import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import '../utils/app_log.dart';
import '../utils/date_format.dart';
import 'notification_settings_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  /// Tolerant of records written by older builds or partially corrupted
  /// storage: one bad entry used to throw and wipe the whole feed.
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        isRead: json['isRead'] == true,
      );

  String get timeAgo => AppDate.relative(createdAt);
}

class NotificationService {
  static const _storageKey = 'app_notifications';
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _nextNativeId =
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 30);

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // Navigate to notification feed page
    navigatorKey.currentState?.pushNamed('/notifications-feed');
  }

  /// Initialize native notifications - call this once at app startup
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Show a native device notification
  static Future<void> showNativeNotification({
    required String title,
    required String body,
  }) async {
    if (!await NotificationSettingsService.isNotificationsEnabled()) return;
    await initialize();

    final sound = await NotificationSettingsService.shouldPlaySound();
    final vibrate = await NotificationSettingsService.shouldVibrate();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'tripnest_channel',
        'TripNest Notifications',
        channelDescription: 'Notifications for TripNest events',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: sound,
        enableVibration: vibrate,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: sound,
      ),
    );

    // Ids must be unique: the plugin replaces a notification whose id is
    // already showing, so a per-second id silently dropped notifications.
    _nextNativeId = (_nextNativeId + 1) % (1 << 30);
    await _flutterLocalNotificationsPlugin.show(
        _nextNativeId, title, body, details);
  }

  static Future<void> addNotification({
    required String title,
    required String body,
    bool showNative = true,
  }) async {
    // Show native device notification
    if (showNative) {
      await showNativeNotification(title: title, body: body);
    }

    // Save to local storage for feed
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();

    final newNotification = AppNotification(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );

    notifications.insert(0, newNotification);

    // Keep only last 50 notifications
    final toSave = notifications.take(50).toList();
    final jsonList = toSave.map((n) => n.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final result = <AppNotification>[];
      for (final entry in jsonList) {
        if (entry is! Map<String, dynamic>) continue;
        try {
          result.add(AppNotification.fromJson(entry));
        } catch (e) {
          AppLog.e('Skipping unreadable notification', e);
        }
      }
      return result;
    } catch (e) {
      AppLog.e('Failed to read notification feed', e);
      return [];
    }
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();

    final updated = notifications
        .map((n) => AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              createdAt: n.createdAt,
              isRead: true,
            ))
        .toList();

    final jsonList = updated.map((n) => n.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
