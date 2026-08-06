import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../../../main.dart';
import 'notification_settings_service.dart';

/// Service for showing local notifications with sound and vibration
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Monotonic notification id.
  ///
  /// The old `millisecondsSinceEpoch ~/ 1000` collided for anything posted
  /// within the same second, and the plugin *replaces* a notification whose id
  /// already exists — so a chat notification could silently eat a booking
  /// confirmation.
  static int _nextId =
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 30);

  static int _newId() {
    // Android notification ids must fit in a 32-bit int.
    _nextId = (_nextId + 1) % (1 << 30);
    return _nextId;
  }

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Enable foreground notifications on iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // Show notifications even when app is in foreground
      notificationCategories: [],
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    _initialized = true;
    debugPrint('LocalNotificationService initialized');
  }

  /// True when the user has notifications switched on at all.
  static Future<bool> _notificationsAllowed() =>
      NotificationSettingsService.isNotificationsEnabled();

  /// Builds platform details that respect the user's sound preference. These
  /// can't be `const` any more precisely because they depend on settings.
  static Future<NotificationDetails> _details({
    required String channelId,
    required String channelName,
    required String channelDescription,
    AndroidNotificationCategory? androidCategory,
    bool timeSensitive = false,
  }) async {
    final sound = await NotificationSettingsService.shouldPlaySound();
    final vibrate = await NotificationSettingsService.shouldVibrate();

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound,
        enableVibration: vibrate,
        icon: '@mipmap/ic_launcher',
        category: androidCategory,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: sound,
        interruptionLevel: timeSensitive
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

  /// Handle notification tap based on payload
  static void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      navigatorKey.currentState?.pushNamed('/notifications-feed');
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'message') {
        final roomId = data['roomId'] as String?;
        final roomName = data['roomName'] as String?;
        if (roomId != null && roomName != null) {
          navigatorKey.currentState?.pushNamed(
            '/chat-thread',
            arguments: {'roomId': roomId, 'roomName': roomName},
          );
          return;
        }
      }

      if (type == 'aqi') {
        // Navigate to notification feed for AQI notifications
        navigatorKey.currentState?.pushNamed('/notifications-feed');
        return;
      }

      // Default fallback
      navigatorKey.currentState?.pushNamed('/notifications-feed');
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
      navigatorKey.currentState?.pushNamed('/notifications-feed');
    }
  }

  /// Request notification permissions (iOS)
  static Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
    }

    if (iOS != null) {
      await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return true;
  }

  /// Show a booking confirmation notification with sound and vibration
  static Future<void> showBookingNotification({
    required String bookingId,
    required String eventTitle,
    required int ticketCount,
    required double totalPrice,
  }) async {
    if (!await _notificationsAllowed()) return;
    if (!_initialized) {
      await initialize();
    }

    await _vibrate();

    final notificationDetails = await _details(
      channelId: 'booking_channel',
      channelName: 'Booking Notifications',
      channelDescription: 'Notifications for booking confirmations',
      timeSensitive: true,
    );

    await _notifications.show(
      _newId(),
      'Booking Confirmed!',
      'Your booking for "$eventTitle" ($ticketCount tickets, ฿${totalPrice.toStringAsFixed(2)}) has been confirmed!',
      notificationDetails,
    );

    debugPrint('Booking notification shown for: $eventTitle');
  }

  /// Show a generic notification
  static Future<void> showNotification({
    required String title,
    required String body,
    bool vibrate = true,
  }) async {
    if (!await _notificationsAllowed()) return;
    if (!_initialized) {
      await initialize();
    }

    if (vibrate) {
      await _vibrate();
    }

    final notificationDetails = await _details(
      channelId: 'general_channel',
      channelName: 'General Notifications',
      channelDescription: 'General app notifications',
    );

    await _notifications.show(
      _newId(),
      title,
      body,
      notificationDetails,
    );
  }

  /// Show a message notification
  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String roomId,
    required String roomName,
  }) async {
    if (!await _notificationsAllowed()) return;
    if (!_initialized) {
      await initialize();
    }

    await _vibrate(duration: 300);

    final notificationDetails = await _details(
      channelId: 'message_channel',
      channelName: 'Message Notifications',
      channelDescription: 'Notifications for new messages',
      androidCategory: AndroidNotificationCategory.message,
      timeSensitive: true,
    );

    // Create payload with chat room info for navigation
    final payload = jsonEncode({
      'type': 'message',
      'roomId': roomId,
      'roomName': roomName,
    });

    await _notifications.show(
      _newId(),
      senderName,
      message,
      notificationDetails,
      payload: payload,
    );

    debugPrint('Message notification shown from: $senderName');
  }

  /// Show an AQI/Air Quality notification
  static Future<void> showAqiNotification({
    required String title,
    required String body,
    required int aqiValue,
  }) async {
    if (!await _notificationsAllowed()) return;
    if (!_initialized) {
      await initialize();
    }

    await _vibrate(duration: 300);

    final notificationDetails = await _details(
      channelId: 'aqi_channel',
      channelName: 'Air Quality Notifications',
      channelDescription: 'Notifications for air quality updates',
      timeSensitive: true,
    );

    // Create payload for navigation
    final payload = jsonEncode({
      'type': 'aqi',
      'aqiValue': aqiValue,
    });

    await _notifications.show(
      _newId(),
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('AQI notification shown: AQI $aqiValue');
  }

  /// Vibrate the device, unless the user turned vibration (or notifications)
  /// off in settings.
  static Future<void> _vibrate({int duration = 500}) async {
    if (!await NotificationSettingsService.shouldVibrate()) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }
}
