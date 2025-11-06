import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'https://underground-brittni-tripnest-82c64bf9.koyeb.app/api';

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _roleKey = 'role';

  /// Save user session data
  static Future<void> _saveSession({
    required String token,
    required String userId,
    required String username,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_roleKey, role);
  }

  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Get stored user data
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_userIdKey),
      'username': prefs.getString(_usernameKey),
      'email': prefs.getString(_emailKey),
      'role': prefs.getString(_roleKey),
    };
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
  }

  /// Register a new user
  /// Returns a Map with the response data if successful, or throws an exception
  static Future<Map<String, dynamic>> register({
    required String username,
    required String phone_number,
    required String email,
    required String password,
    String role = 'user', // default role is 'user'
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'phone_number': phone_number,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful
        return data;
      } else {
        // Registration failed
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Login successful - save session
        if (data['token'] != null && data['user'] != null) {
          await _saveSession(
            token: data['token'],
            userId: data['user']['id'],
            username: data['user']['username'],
            email: data['user']['email'],
            role: data['user']['role'],
          );
        }
        return data;
      } else {
        // Login failed
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get user profile from API
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=================================');
      print('USER PROFILE RESPONSE');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=================================');

      if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      }

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('JSON Parse Error: $e');
        if (response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html>')) {
          throw Exception('Server error occurred. Please try again later.');
        }
        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        print('=================================');
        print('USER PROFILE LOADED');
        print('=================================');
        print('User ID: ${data['user']['_id']}');
        print('Username: ${data['user']['username']}');
        print('Email: ${data['user']['email']}');
        print('Phone: ${data['user']['phone_number']}');
        print('Role: ${data['user']['role']}');
        print('=================================');
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } on FormatException catch (e) {
      print('Format Exception: $e');
      throw Exception('Server response format error');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
