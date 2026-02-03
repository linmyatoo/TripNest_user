import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notification.dart';

class NotificationService {
  static const String baseUrl = 'https://naylinhtet.me/api';

  /// Get auth token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Fetch all notifications for the authenticated user
  static Future<List<AppNotification>> getNotifications() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/notifications');

      print('Fetching notifications from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/notifications/$notificationId/read');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
