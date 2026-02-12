import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_notification_service.dart';

/// Model for AQI data
class AqiData {
  final int aqi;
  final int pm25;
  final int pm10;
  final String cityName;
  final DateTime timestamp;
  final String dominantPollutant;
  final double temperature;
  final double humidity;

  AqiData({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.cityName,
    required this.timestamp,
    required this.dominantPollutant,
    required this.temperature,
    required this.humidity,
  });

  /// Get AQI level description
  String get level {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  /// Get color based on AQI level (for backgrounds/accents)
  int get colorValue {
    if (aqi <= 50) return 0xFF16A34A; // Darker Green for visibility
    if (aqi <= 100) return 0xFFCA8A04; // Dark Yellow/Amber for visibility
    if (aqi <= 150) return 0xFFEA580C; // Dark Orange
    if (aqi <= 200) return 0xFFDC2626; // Red
    if (aqi <= 300) return 0xFF7C3AED; // Purple
    return 0xFF991B1B; // Dark Maroon
  }

  /// Get text color for AQI badge (ensures contrast)
  int get textColorValue {
    return 0xFFFFFFFF; // White text works on all our colors now
  }

  /// Get background color for cards/containers
  int get backgroundColorValue {
    if (aqi <= 50) return 0xFFDCFCE7; // Light green
    if (aqi <= 100) return 0xFFFEF9C3; // Light yellow
    if (aqi <= 150) return 0xFFFFEDD5; // Light orange
    if (aqi <= 200) return 0xFFFEE2E2; // Light red
    if (aqi <= 300) return 0xFFF3E8FF; // Light purple
    return 0xFFFEE2E2; // Light red
  }

  /// Get health recommendation
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

  factory AqiData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final iaqi = data['iaqi'] as Map<String, dynamic>? ?? {};
    final city = data['city'] as Map<String, dynamic>? ?? {};
    final time = data['time'] as Map<String, dynamic>? ?? {};

    return AqiData(
      aqi: (data['aqi'] as num?)?.toInt() ?? 0,
      pm25:
          ((iaqi['pm25'] as Map<String, dynamic>?)?['v'] as num?)?.toInt() ?? 0,
      pm10:
          ((iaqi['pm10'] as Map<String, dynamic>?)?['v'] as num?)?.toInt() ?? 0,
      cityName: city['name'] as String? ?? 'Unknown',
      timestamp:
          DateTime.tryParse(time['iso'] as String? ?? '') ?? DateTime.now(),
      dominantPollutant: data['dominentpol'] as String? ?? 'pm25',
      temperature:
          ((iaqi['t'] as Map<String, dynamic>?)?['v'] as num?)?.toDouble() ?? 0,
      humidity:
          ((iaqi['h'] as Map<String, dynamic>?)?['v'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'aqi': aqi,
        'pm25': pm25,
        'pm10': pm10,
        'cityName': cityName,
        'timestamp': timestamp.toIso8601String(),
        'dominantPollutant': dominantPollutant,
        'temperature': temperature,
        'humidity': humidity,
      };

  factory AqiData.fromStoredJson(Map<String, dynamic> json) => AqiData(
        aqi: json['aqi'] as int? ?? 0,
        pm25: json['pm25'] as int? ?? 0,
        pm10: json['pm10'] as int? ?? 0,
        cityName: json['cityName'] as String? ?? 'Unknown',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        dominantPollutant: json['dominantPollutant'] as String? ?? 'pm25',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
        humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      );
}

/// Service for fetching and managing Air Quality Index data
class AqiService {
  static const String _apiToken = '004eb8cf677c3893baf0b3a7267ba39d3359f777';
  static const String _baseUrl = 'https://api.waqi.info';

  // Storage keys
  static const String _lastAqiKey = 'last_aqi_value';
  static const String _lastAqiDataKey = 'last_aqi_data';
  static const String _lastNotificationDateKey = 'last_aqi_notification_date';
  static const String _lastNotificationAqiKey = 'last_notification_aqi_value';

  /// Fetch current AQI data based on user's IP location
  static Future<AqiData?> getCurrentAqi() async {
    try {
      final url = Uri.parse('$_baseUrl/feed/here/?token=$_apiToken');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['status'] == 'ok') {
          final aqiData = AqiData.fromJson(json);
          await _storeAqiData(aqiData);
          await _checkAndSendNotification(aqiData);
          return aqiData;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching AQI data: $e');
      return null;
    }
  }

  /// Fetch AQI data for a specific city
  static Future<AqiData?> getAqiForCity(String cityName) async {
    try {
      final url = Uri.parse('$_baseUrl/feed/$cityName/?token=$_apiToken');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['status'] == 'ok') {
          return AqiData.fromJson(json);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching AQI for city $cityName: $e');
      return null;
    }
  }

  /// Get cached AQI data from local storage
  static Future<AqiData?> getCachedAqi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_lastAqiDataKey);
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        return AqiData.fromStoredJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached AQI: $e');
      return null;
    }
  }

  /// Store AQI data locally
  static Future<void> _storeAqiData(AqiData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastAqiDataKey, jsonEncode(data.toJson()));
      await prefs.setInt(_lastAqiKey, data.aqi);
    } catch (e) {
      debugPrint('Error storing AQI data: $e');
    }
  }

  /// Check if notification should be sent and send it
  static Future<void> _checkAndSendNotification(AqiData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastNotificationDate = prefs.getString(_lastNotificationDateKey);
      final lastNotificationAqi = prefs.getInt(_lastNotificationAqiKey) ?? 0;

      bool shouldNotify = false;
      String notificationReason = '';

      // Check if it's a new day - send daily notification
      if (lastNotificationDate != today) {
        shouldNotify = true;
        notificationReason = 'daily';
      }
      // Check if AQI changed by 50+ points (significant change)
      else if (lastNotificationAqi > 0) {
        final change = (data.aqi - lastNotificationAqi).abs();
        // 0.5 ratio of change or 50 points, whichever interpretation
        // Using 50 points as significant change threshold
        if (change >= 50) {
          shouldNotify = true;
          notificationReason = 'significant_change';
        }
      }

      if (shouldNotify) {
        await _sendAqiNotification(data, notificationReason);
        await prefs.setString(_lastNotificationDateKey, today);
        await prefs.setInt(_lastNotificationAqiKey, data.aqi);
      }
    } catch (e) {
      debugPrint('Error checking AQI notification: $e');
    }
  }

  /// Send AQI notification
  static Future<void> _sendAqiNotification(AqiData data, String reason) async {
    String title;
    String body;

    if (reason == 'daily') {
      title = '🌤 Daily Air Quality Update';
      body =
          '${data.cityName}: AQI ${data.aqi} (${data.level}). PM2.5: ${data.pm25}. ${data.healthRecommendation}';
    } else {
      final direction = data.aqi > (await _getLastNotificationAqi())
          ? 'increased'
          : 'improved';
      title = '⚠️ Air Quality $direction';
      body =
          '${data.cityName}: AQI ${data.aqi} (${data.level}). PM2.5: ${data.pm25}. ${data.healthRecommendation}';
    }

    await LocalNotificationService.showAqiNotification(
      title: title,
      body: body,
      aqiValue: data.aqi,
    );
  }

  static Future<int> _getLastNotificationAqi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastNotificationAqiKey) ?? 0;
  }

  /// Get stored AQI notifications for display in notification feed
  static Future<List<AqiNotificationData>> getAqiNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('aqi_notifications') ?? [];
      return stored
          .map((s) => AqiNotificationData.fromJson(
              jsonDecode(s) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error getting AQI notifications: $e');
      return [];
    }
  }

  /// Store AQI notification for display
  static Future<void> storeAqiNotification(
      AqiNotificationData notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('aqi_notifications') ?? [];
      stored.insert(0, jsonEncode(notification.toJson()));
      // Keep only last 20 notifications
      if (stored.length > 20) {
        stored.removeRange(20, stored.length);
      }
      await prefs.setStringList('aqi_notifications', stored);
    } catch (e) {
      debugPrint('Error storing AQI notification: $e');
    }
  }

  /// Force refresh and notify (for testing/manual refresh)
  static Future<AqiData?> refreshAndNotify() async {
    final data = await getCurrentAqi();
    if (data != null) {
      // Force send notification regardless of timing
      await _sendAqiNotification(data, 'manual');
      await storeAqiNotification(AqiNotificationData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        aqi: data.aqi,
        pm25: data.pm25,
        cityName: data.cityName,
        level: data.level,
        recommendation: data.healthRecommendation,
        timestamp: DateTime.now(),
      ));
    }
    return data;
  }
}

/// Model for stored AQI notification data
class AqiNotificationData {
  final String id;
  final int aqi;
  final int pm25;
  final String cityName;
  final String level;
  final String recommendation;
  final DateTime timestamp;

  AqiNotificationData({
    required this.id,
    required this.aqi,
    required this.pm25,
    required this.cityName,
    required this.level,
    required this.recommendation,
    required this.timestamp,
  });

  factory AqiNotificationData.fromJson(Map<String, dynamic> json) =>
      AqiNotificationData(
        id: json['id'] as String,
        aqi: json['aqi'] as int,
        pm25: json['pm25'] as int,
        cityName: json['cityName'] as String,
        level: json['level'] as String,
        recommendation: json['recommendation'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'aqi': aqi,
        'pm25': pm25,
        'cityName': cityName,
        'level': level,
        'recommendation': recommendation,
        'timestamp': timestamp.toIso8601String(),
      };
}
