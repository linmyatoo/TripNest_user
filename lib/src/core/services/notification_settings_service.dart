import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Storage keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'notification_sound_enabled';
  static const String _vibrateEnabledKey = 'notification_vibrate_enabled';
  static const String _specialOffersKey = 'notification_special_offers';
  static const String _paymentsKey = 'notification_payments';
  static const String _cashbackKey = 'notification_cashback';
  static const String _appUpdatesKey = 'notification_app_updates';

  // ==================== Getters ====================

  static Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  static Future<bool> isVibrateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrateEnabledKey) ?? true;
  }

  static Future<bool> isSpecialOffersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_specialOffersKey) ?? true;
  }

  static Future<bool> isPaymentsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paymentsKey) ?? true;
  }

  static Future<bool> isCashbackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cashbackKey) ?? true;
  }

  static Future<bool> isAppUpdatesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appUpdatesKey) ?? true;
  }

  // ==================== Setters ====================

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  static Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
  }

  static Future<void> setVibrateEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrateEnabledKey, value);
  }

  static Future<void> setSpecialOffersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_specialOffersKey, value);
  }

  static Future<void> setPaymentsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_paymentsKey, value);
  }

  static Future<void> setCashbackEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cashbackKey, value);
  }

  static Future<void> setAppUpdatesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appUpdatesKey, value);
  }

  // ==================== Bulk Operations ====================

  static Future<Map<String, bool>> getAllSettings() async {
    return {
      'notifications': await isNotificationsEnabled(),
      'sound': await isSoundEnabled(),
      'vibrate': await isVibrateEnabled(),
      'specialOffers': await isSpecialOffersEnabled(),
      'payments': await isPaymentsEnabled(),
      'cashback': await isCashbackEnabled(),
      'appUpdates': await isAppUpdatesEnabled(),
    };
  }

  static Future<void> saveAllSettings({
    required bool notifications,
    required bool sound,
    required bool vibrate,
    required bool specialOffers,
    required bool payments,
    required bool cashback,
    required bool appUpdates,
  }) async {
    await setNotificationsEnabled(notifications);
    await setSoundEnabled(sound);
    await setVibrateEnabled(vibrate);
    await setSpecialOffersEnabled(specialOffers);
    await setPaymentsEnabled(payments);
    await setCashbackEnabled(cashback);
    await setAppUpdatesEnabled(appUpdates);
  }

  // ==================== Helper Methods ====================

  /// Check if notification should play sound based on settings
  static Future<bool> shouldPlaySound() async {
    final notificationsEnabled = await isNotificationsEnabled();
    final soundEnabled = await isSoundEnabled();
    return notificationsEnabled && soundEnabled;
  }

  /// Check if notification should vibrate based on settings
  static Future<bool> shouldVibrate() async {
    final notificationsEnabled = await isNotificationsEnabled();
    final vibrateEnabled = await isVibrateEnabled();
    return notificationsEnabled && vibrateEnabled;
  }
}
