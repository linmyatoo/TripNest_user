import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'http_client.dart';
import 'local_notification_service.dart';
import 'notification_service.dart';

class AirQualityData {
  /// Every reading is nullable because WAQI genuinely reports "no data".
  ///
  /// Defaulting a missing reading to 0 is worse than showing nothing: AQI 0
  /// renders as "Good — perfect for outdoor activities", i.e. the app invents
  /// health advice from a measurement it never received.
  final int? aqi;
  final double? pm25;
  final double? pm10;
  final String cityName;
  final DateTime updatedAt;
  final double? temperature;

  AirQualityData({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.cityName,
    required this.updatedAt,
    this.temperature,
  });

  bool get hasAqi => aqi != null;

  /// Value for the AQI badge; `--` when the station reported no index.
  String get aqiDisplay => aqi?.toString() ?? '--';

  String get aqiLevel {
    final value = aqi;
    if (value == null) return 'Unavailable';
    if (value <= 50) return 'Good';
    if (value <= 100) return 'Moderate';
    if (value <= 150) return 'Unhealthy for Sensitive Groups';
    if (value <= 200) return 'Unhealthy';
    if (value <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // Alias for compatibility
  String get level => aqiLevel;

  int get colorValue {
    final value = aqi;
    if (value == null) return 0xFF9AA0A6; // Neutral grey — no reading
    if (value <= 50) return 0xFF16A34A; // Darker Green
    if (value <= 100) return 0xFFCA8A04; // Dark Amber
    if (value <= 150) return 0xFFEA580C; // Dark Orange
    if (value <= 200) return 0xFFDC2626; // Red
    if (value <= 300) return 0xFF7C3AED; // Purple
    return 0xFF991B1B; // Dark Maroon
  }

  int get backgroundColorValue {
    final value = aqi;
    if (value == null) return 0xFFF1F3F4; // Light grey
    if (value <= 50) return 0xFFDCFCE7; // Light green
    if (value <= 100) return 0xFFFEF9C3; // Light yellow
    if (value <= 150) return 0xFFFFEDD5; // Light orange
    if (value <= 200) return 0xFFFEE2E2; // Light red
    if (value <= 300) return 0xFFF3E8FF; // Light purple
    return 0xFFFEE2E2; // Light red
  }

  String get healthRecommendation {
    final value = aqi;
    if (value == null) {
      return 'No air quality reading is available for this location right now.';
    }
    if (value <= 50) {
      return 'Air quality is good. Perfect for outdoor activities!';
    }
    if (value <= 100) {
      return 'Air quality is acceptable. Sensitive individuals should limit prolonged outdoor exertion.';
    }
    if (value <= 150) {
      return 'Sensitive groups should reduce outdoor activities. Everyone else can continue normally.';
    }
    if (value <= 200) {
      return 'Everyone may begin to experience health effects. Limit outdoor activities.';
    }
    if (value <= 300) {
      return 'Health alert! Everyone should avoid outdoor activities.';
    }
    return 'Emergency conditions! Stay indoors and keep windows closed.';
  }

  /// Formats a pollutant reading, or `--` when it is missing.
  static String formatReading(double? value, {int decimals = 1}) =>
      value?.toStringAsFixed(decimals) ?? '--';

  Map<String, dynamic> toJson() => {
        'aqi': aqi,
        'pm25': pm25,
        'pm10': pm10,
        'cityName': cityName,
        'updatedAt': updatedAt.toIso8601String(),
        'temperature': temperature,
      };

  factory AirQualityData.fromJson(Map<String, dynamic> json) => AirQualityData(
        aqi: parseInt(json['aqi']),
        pm25: parseDouble(json['pm25']),
        pm10: parseDouble(json['pm10']),
        cityName: json['cityName']?.toString() ?? 'Unknown',
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        temperature: parseDouble(json['temperature']),
      );

  /// Returns null for anything that isn't a number.
  ///
  /// WAQI sends the String `"-"` for unavailable readings, so this must not
  /// throw a TypeError — and must not pretend the value was 0.
  static int? parseInt(Object? value) => parseDouble(value)?.toInt();

  static double? parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    // Handles "42" and "42.7" alike; returns null for "-", "", null.
    return double.tryParse(value?.toString().trim() ?? '');
  }
}

class AirQualityService {
  static const String _lastPm25Key = 'last_pm25_value';
  static const String _lastCheckDateKey = 'last_aqi_check_date';
  static const String _cachedAqiDataKey = 'cached_aqi_data';
  static const double _changeThreshold = 50;

  /// Preference keys this service owns, so logout can clear them.
  static const List<String> storageKeys = [
    _lastPm25Key,
    _lastCheckDateKey,
    _cachedAqiDataKey,
  ];

  /// Get air quality data for current location
  static Future<AirQualityData?> getAirQuality(
      {String location = 'here'}) async {
    if (ApiConfig.isWaqiTokenMissing) {
      debugPrint('Air quality disabled: WAQI token not configured.');
      return null;
    }
    try {
      final response = await Http.client.get(
        Uri.parse(
            '${ApiConfig.waqiBaseUrl}/$location/?token=${ApiConfig.waqiApiToken}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok' && data['data'] is Map) {
          final aqiData = data['data'] as Map;
          // On a non-ok status WAQI puts an error *string* in `data`, hence the
          // type check above.
          final iaqi = aqiData['iaqi'] is Map ? aqiData['iaqi'] as Map : {};
          final city = aqiData['city'] is Map ? aqiData['city'] as Map : {};

          final airQuality = AirQualityData(
            aqi: AirQualityData.parseInt(aqiData['aqi']),
            pm25: AirQualityData.parseDouble(_reading(iaqi, 'pm25')),
            pm10: AirQualityData.parseDouble(_reading(iaqi, 'pm10')),
            cityName: city['name']?.toString() ?? 'Unknown',
            updatedAt: DateTime.now(),
            temperature: AirQualityData.parseDouble(_reading(iaqi, 't')),
          );

          // Cache the data
          await _cacheAqiData(airQuality);

          return airQuality;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching air quality: $e');
      return null;
    }
  }

  /// Pulls `iaqi.<pollutant>.v` defensively — any level of that path can be
  /// missing or the wrong type.
  static Object? _reading(Map iaqi, String key) {
    final entry = iaqi[key];
    return entry is Map ? entry['v'] : null;
  }

  /// Cache AQI data locally
  static Future<void> _cacheAqiData(AirQualityData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedAqiDataKey, jsonEncode(data.toJson()));
  }

  /// Get cached AQI data
  static Future<AirQualityData?> getCachedAqi() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cachedAqiDataKey);
    if (jsonStr == null) return null;

    try {
      return AirQualityData.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  /// Check and send notification if needed (once daily + significant change)
  static bool _isChecking = false;

  static Future<void> checkAndNotify() async {
    // Prevent concurrent calls
    if (_isChecking) return;
    _isChecking = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckDate = prefs.getString(_lastCheckDateKey);
      final lastPm25 = prefs.getDouble(_lastPm25Key);

      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      final alreadyNotifiedToday = lastCheckDate == todayStr;

      // Fetch current air quality
      final aqData = await getAirQuality();
      if (aqData == null) return;

      // Nothing to report if the station sent no usable reading.
      if (!aqData.hasAqi && aqData.pm25 == null) return;

      final pm25 = aqData.pm25;
      bool shouldNotify = false;
      bool isDailyUpdate = false;
      String notificationReason = '';

      if (!alreadyNotifiedToday) {
        // Daily notification (first check of the day)
        shouldNotify = true;
        isDailyUpdate = true;
        notificationReason = 'Daily air quality update';
      } else if (lastPm25 != null && pm25 != null) {
        // Check for significant change (50+ threshold). Both samples must be
        // real readings — comparing against a missing value that defaulted to
        // 0 produced a fake "PM2.5 decreased by 50" alert.
        final change = (pm25 - lastPm25).abs();
        if (change >= _changeThreshold) {
          shouldNotify = true;
          final direction = pm25 > lastPm25 ? 'increased' : 'decreased';
          notificationReason =
              'PM2.5 $direction by ${change.toStringAsFixed(1)}';
        }
      }

      if (shouldNotify) {
        // A failed send must not abort the rest of the bookkeeping below, and
        // must not mark today as already notified.
        final sent = await _notify(aqData, notificationReason);
        if (sent && isDailyUpdate) {
          await prefs.setString(_lastCheckDateKey, todayStr);
        }
      }

      if (pm25 != null) {
        await prefs.setDouble(_lastPm25Key, pm25);
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Sends the alert to both the in-app feed and the device.
  ///
  /// Returns false when the notification did not go out, so the caller does
  /// not record it as delivered.
  static Future<bool> _notify(AirQualityData aqData, String reason) async {
    final title = 'Air Quality Alert - ${aqData.cityName}';
    final body = 'AQI: ${aqData.aqiDisplay} (${aqData.aqiLevel})\n'
        'PM2.5: ${AirQualityData.formatReading(aqData.pm25)} μg/m³\n$reason';

    try {
      // Feed entry only — the native notification is sent below so it lands on
      // the AQI channel and carries the payload that routes a tap.
      await NotificationService.addNotification(
        title: title,
        body: body,
        showNative: false,
      );
      await LocalNotificationService.showAqiNotification(
        title: title,
        body: body,
        aqiValue: aqData.aqi ?? 0,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to send air quality notification: $e');
      return false;
    }
  }

  /// Get cached PM2.5 value
  static Future<double?> getCachedPm25() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastPm25Key);
  }

  /// Drop all cached AQI state (called on logout)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in storageKeys) {
      await prefs.remove(key);
    }
  }
}
