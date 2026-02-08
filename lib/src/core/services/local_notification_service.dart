import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../../../main.dart';

/// Service for showing local notifications with sound and vibration
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

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
    if (!_initialized) {
      await initialize();
    }

    // Vibrate the device
    await _vibrate();

    // Notification details with sound
    const androidDetails = AndroidNotificationDetails(
      'booking_channel',
      'Booking Notifications',
      channelDescription: 'Notifications for booking confirmations',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Show banner even when app is in foreground
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
    if (!_initialized) {
      await initialize();
    }

    if (vibrate) {
      await _vibrate();
    }

    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
    if (!_initialized) {
      await initialize();
    }

    await _vibrate(duration: 300);

    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Notifications',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.message,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload with chat room info for navigation
    final payload = jsonEncode({
      'type': 'message',
      'roomId': roomId,
      'roomName': roomName,
    });

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      senderName,
      message,
      notificationDetails,
      payload: payload,
    );

    debugPrint('Message notification shown from: $senderName');
  }

  /// Vibrate the device
  static Future<void> _vibrate({int duration = 500}) async {
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
