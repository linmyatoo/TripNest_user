import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

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

    await _notifications.initialize(initSettings);

    _initialized = true;
    debugPrint('LocalNotificationService initialized');
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
