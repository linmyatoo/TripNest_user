import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AirQualityData {
  final int aqi;
  final double pm25;
  final double pm10;
  final String cityName;
  final DateTime updatedAt;
  final double temperature;

  AirQualityData({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.cityName,
    required this.updatedAt,
    this.temperature = 0,
  });

  String get aqiLevel {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // Alias for compatibility
  String get level => aqiLevel;

  int get colorValue {
    if (aqi <= 50) return 0xFF16A34A; // Darker Green
    if (aqi <= 100) return 0xFFCA8A04; // Dark Amber
    if (aqi <= 150) return 0xFFEA580C; // Dark Orange
    if (aqi <= 200) return 0xFFDC2626; // Red
    if (aqi <= 300) return 0xFF7C3AED; // Purple
    return 0xFF991B1B; // Dark Maroon
  }

  int get backgroundColorValue {
    if (aqi <= 50) return 0xFFDCFCE7; // Light green
    if (aqi <= 100) return 0xFFFEF9C3; // Light yellow
    if (aqi <= 150) return 0xFFFFEDD5; // Light orange
    if (aqi <= 200) return 0xFFFEE2E2; // Light red
    if (aqi <= 300) return 0xFFF3E8FF; // Light purple
    return 0xFFFEE2E2; // Light red
  }

  String get healthRecommendation {
    if (aqi <= 50) {
      return 'Air quality is good. Perfect for outdoor activities!';
    }
    if (aqi <= 100) {
      return 'Air quality is acceptable. Sensitive individuals should limit prolonged outdoor exertion.';
    }
    if (aqi <= 150) {
      return 'Sensitive groups should reduce outdoor activities. Everyone else can continue normally.';
    }
    if (aqi <= 200) {
      return 'Everyone may begin to experience health effects. Limit outdoor activities.';
    }
    if (aqi <= 300) {
      return 'Health alert! Everyone should avoid outdoor activities.';
    }
    return 'Emergency conditions! Stay indoors and keep windows closed.';
  }

  Map<String, dynamic> toJson() => {
        'aqi': aqi,
        'pm25': pm25,
        'pm10': pm10,
        'cityName': cityName,
        'updatedAt': updatedAt.toIso8601String(),
        'temperature': temperature,
      };

  factory AirQualityData.fromJson(Map<String, dynamic> json) => AirQualityData(
        aqi: json['aqi'] ?? 0,
        pm25: (json['pm25'] ?? 0).toDouble(),
        pm10: (json['pm10'] ?? 0).toDouble(),
        cityName: json['cityName'] ?? 'Unknown',
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
        temperature: (json['temperature'] ?? 0).toDouble(),
      );
}

class AirQualityService {
  static const String _apiToken = '004eb8cf677c3893baf0b3a7267ba39d3359f777';
  static const String _baseUrl = 'https://api.waqi.info/feed';
  static const String _lastPm25Key = 'last_pm25_value';
  static const String _lastCheckDateKey = 'last_aqi_check_date';
  static const String _cachedAqiDataKey = 'cached_aqi_data';
  static const double _changeThreshold = 50;

  /// Get air quality data for current location
  static Future<AirQualityData?> getAirQuality(
      {String location = 'here'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$location/?token=$_apiToken'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          final aqiData = data['data'];
          final iaqi = aqiData['iaqi'] ?? {};

          final airQuality = AirQualityData(
            aqi: aqiData['aqi'] ?? 0,
            pm25: (iaqi['pm25']?['v'] ?? 0).toDouble(),
            pm10: (iaqi['pm10']?['v'] ?? 0).toDouble(),
            cityName: aqiData['city']?['name'] ?? 'Unknown',
            updatedAt: DateTime.now(),
            temperature: (iaqi['t']?['v'] ?? 0).toDouble(),
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

  /// Check and send notification if needed (once daily or on significant change)
  static Future<void> checkAndNotify() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDate = prefs.getString(_lastCheckDateKey);
    final lastPm25 = prefs.getDouble(_lastPm25Key);

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final alreadyCheckedToday = lastCheckDate == todayStr;

    // Fetch current air quality
    final aqData = await getAirQuality();
    if (aqData == null) return;

    final currentPm25 = aqData.pm25;
    bool shouldNotify = false;
    String notificationReason = '';

    // Check if we should send notification
    if (!alreadyCheckedToday) {
      // Daily notification
      shouldNotify = true;
      notificationReason = 'Daily air quality update';
    } else if (lastPm25 != null) {
      // Check for significant change
      final change = (currentPm25 - lastPm25).abs();
      if (change >= _changeThreshold) {
        shouldNotify = true;
        final direction = currentPm25 > lastPm25 ? 'increased' : 'decreased';
        notificationReason = 'PM2.5 $direction by ${change.toStringAsFixed(1)}';
      }
    }

    if (shouldNotify) {
      // Send notification
      await NotificationService.addNotification(
        title: 'Air Quality Alert - ${aqData.cityName}',
        body:
            'AQI: ${aqData.aqi} (${aqData.aqiLevel})\nPM2.5: ${aqData.pm25.toStringAsFixed(1)} μg/m³\n$notificationReason',
      );

      // Update stored values
      await prefs.setString(_lastCheckDateKey, todayStr);
      await prefs.setDouble(_lastPm25Key, currentPm25);
    } else {
      // Still update the PM2.5 value for change detection
      await prefs.setDouble(_lastPm25Key, currentPm25);
    }
  }

  /// Force check and notify (for manual refresh)
  static Future<AirQualityData?> forceCheckAndNotify() async {
    final aqData = await getAirQuality();
    if (aqData == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    await prefs.setString(_lastCheckDateKey, todayStr);
    await prefs.setDouble(_lastPm25Key, aqData.pm25);

    return aqData;
  }

  /// Get cached PM2.5 value
  static Future<double?> getCachedPm25() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastPm25Key);
  }
}
