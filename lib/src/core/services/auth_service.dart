import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_log.dart';
import 'air_quality_service.dart';
import 'favorite_service.dart';
import 'notification_service.dart';
import 'session.dart';
import 'http_client.dart';
import '../config/api_endpoints.dart';

class AuthService {
  static const String baseUrl = ApiEndpoints.baseUrl;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _nameKey = 'name';
  static const String _emailKey = 'email';
  static const String _roleKey = 'role';

  /// Change password (POST /api/auth/change-password)
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final url = Uri.parse('$baseUrl/auth/change-password');
    final response = await Http.client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    Session.checkResponse(response);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to change password');
    }
  }

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
    await prefs.setString(_nameKey, username);
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
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'role': prefs.getString(_roleKey),
    };
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout user.
  ///
  /// This is the single teardown point for a session: every piece of
  /// per-user state has to be dropped here, or the next account that logs
  /// in on this device inherits it (favorites, notification feed, AQI cache).
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);

    await FavoriteService.clearFavorites();
    await NotificationService.clearAll();
    await AirQualityService.clearCache();
    // Saved credentials are deliberately kept: "remember password" is an
    // explicit opt-in that is supposed to outlive a logout. SecurityService
    // clears them when the user turns that setting off.
  }

  /// Register a new user
  /// Returns a Map with the response data if successful, or throws an exception
  static Future<Map<String, dynamic>> register({
    required String username,
    required String phoneNumber,
    required String email,
    required String password,
    String role = 'user', // default role is 'user'
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');

      AppLog.d('POST /auth/register');

      final response = await Http.client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': username,
          'phone_number': phoneNumber,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      AppLog.d('POST /auth/register -> ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful
        return data;
      } else {
        // Registration failed
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      AppLog.e('Registration failed', e);
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
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

      final response = await Http.client.post(
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
        final token = _extractToken(data);
        if (token != null) {
          final user = _extractUser(data);
          await _saveSession(
            token: token,
            userId: _firstNonEmpty(user, ['id', '_id', 'userId']) ?? 'unknown',
            username: _firstNonEmpty(user, ['username', 'name']) ?? 'User',
            // Use email from response, or fallback to the email used for login
            email: _firstNonEmpty(user, ['email']) ?? email,
            role: _firstNonEmpty(user, ['role']) ?? 'user',
          );
        } else {
          AppLog.e('Login succeeded but no token was found in the response.');
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

  /// Get current user profile from API (GET /api/profile/me)
  static Future<Map<String, dynamic>> getProfileMe() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await Http.client.get(
        Uri.parse('$baseUrl/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLog.d('GET /profile/me -> ${response.statusCode}');
      Session.checkResponse(response);

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
        AppLog.e('JSON parse error', e);
        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get user profile by ID from API (GET /api/profile/:id)
  static Future<Map<String, dynamic>> getProfileById(String userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await Http.client.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLog.d('GET /profile/:id -> ${response.statusCode}');
      Session.checkResponse(response);

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
        AppLog.e('JSON parse error', e);
        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Upload profile image (POST /api/profile/upload-image)
  static Future<String?> uploadProfileImage(String filePath) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('$baseUrl/profile/upload-image');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      AppLog.d('POST /profile/upload-image');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      AppLog.d('POST /profile/upload-image -> ${response.statusCode}');
      Session.checkResponse(response);

      // Handle empty response
      if (response.body.isEmpty) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          AppLog.d('Upload succeeded but no URL was returned');
          return null;
        }
        throw Exception(
            'Server returned empty response (${response.statusCode})');
      }

      // Try to parse JSON response
      try {
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          // Return the image URL from response
          return data['imageUrl'] ??
              data['profilePictureUrl'] ??
              data['url'] ??
              data['data']?['url'];
        } else {
          final data = jsonDecode(response.body);
          throw Exception(
              data['message'] ?? data['error'] ?? 'Failed to upload image');
        }
      } catch (e) {
        if (e is FormatException) {
          // Server returned non-JSON response
          AppLog.e('Upload returned a non-JSON response');
          if (response.statusCode == 404) {
            throw Exception(
                'Image upload endpoint not found. Please check API.');
          } else if (response.statusCode >= 500) {
            throw Exception('Server error during image upload');
          }
          throw Exception('Invalid response from server');
        }
        rethrow;
      }
    } catch (e) {
      AppLog.e('Image upload failed', e);
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Update user profile (PATCH /api/profile/me)
  /// Can include profile image as file path
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profilePictureUrl,
    String? imageFilePath,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // If there's an image file, use multipart request
      if (imageFilePath != null) {
        return await _updateProfileWithImage(
          token: token,
          fullName: fullName,
          phone: phone,
          gender: gender,
          dateOfBirth: dateOfBirth,
          imageFilePath: imageFilePath,
        );
      }

      // Otherwise, use regular JSON request
      final Map<String, dynamic> body = {};
      if (fullName != null) body['fullName'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (gender != null) body['gender'] = gender;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (profilePictureUrl != null) {
        body['profilePictureUrl'] = profilePictureUrl;
      }

      final response = await Http.client.patch(
        Uri.parse('$baseUrl/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      AppLog.d('PATCH /profile/me -> ${response.statusCode}');
    Session.checkResponse(response);
      Session.checkResponse(response);

      if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      }

      if (response.body.isEmpty) {
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {'success': true, 'message': 'Profile updated successfully'};
        }
        throw Exception('Empty response from server');
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        AppLog.e('JSON parse error', e);
        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
            data['message'] ?? data['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Update profile with image using multipart request
  static Future<Map<String, dynamic>> _updateProfileWithImage({
    required String token,
    String? fullName,
    String? phone,
    String? gender,
    String? dateOfBirth,
    required String imageFilePath,
  }) async {
    final uri = Uri.parse('$baseUrl/profile/me');
    final request = http.MultipartRequest('PATCH', uri);

    request.headers['Authorization'] = 'Bearer $token';

    // Add text fields
    if (fullName != null) request.fields['fullName'] = fullName;
    if (phone != null) request.fields['phone'] = phone;
    if (gender != null) request.fields['gender'] = gender;
    if (dateOfBirth != null) request.fields['dateOfBirth'] = dateOfBirth;

    // Add image file with proper content type
    final filename = imageFilePath.split('/').last.toLowerCase();
    String contentType = 'image/jpeg'; // default
    if (filename.endsWith('.png')) {
      contentType = 'image/png';
    } else if (filename.endsWith('.gif')) {
      contentType = 'image/gif';
    } else if (filename.endsWith('.webp')) {
      contentType = 'image/webp';
    }

    // Backend uses 'profilePicture' as the field name
    request.files.add(await http.MultipartFile.fromPath(
      'profilePicture',
      imageFilePath,
      contentType: MediaType.parse(contentType),
      filename: 'profile_image.jpg',
    ));

    AppLog.d('PATCH /profile/me (multipart, $contentType)');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    AppLog.d('PATCH /profile/me -> ${response.statusCode}');
    Session.checkResponse(response);

    if (response.statusCode >= 500) {
      throw Exception('Server error. Please try again later.');
    }

    if (response.body.isEmpty) {
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Profile updated successfully'};
      }
      throw Exception('Empty response from server');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      AppLog.e('JSON parse error', e);
      throw Exception('Invalid server response');
    }

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Failed to update profile');
    }
  }

  /// Get user profile from API
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await Http.client.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLog.d('GET /user/profile -> ${response.statusCode}');
      Session.checkResponse(response);

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
        AppLog.e('JSON parse error', e);
        if (response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html>')) {
          throw Exception('Server error occurred. Please try again later.');
        }
        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        AppLog.d('User profile loaded');
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } on FormatException catch (e) {
      AppLog.e('Server response format error', e);
      throw Exception('Server response format error');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Forgot password - sends reset link to email
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await Http.client.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      AppLog.d('POST /auth/forgot-password -> ${response.statusCode}');

      // Handle server errors
      if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      }

      // Handle empty response
      if (response.body.isEmpty) {
        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Reset link sent to your email'};
        } else {
          throw Exception('Failed to send reset link');
        }
      }

      // Try to parse JSON response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        AppLog.e('JSON parse error', e);

        if (response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html>')) {
          throw Exception('Server error occurred. Please try again later.');
        }

        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to send reset link');
      }
    } on FormatException catch (e) {
      AppLog.e('Server response format error', e);
      throw Exception('Server response format error');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static String? _extractToken(Map<String, dynamic> payload) {
    final candidates = [
      payload['token'],
      payload['accessToken'],
      payload['access_token'],
      payload['jwt'],
      if (payload['data'] is Map<String, dynamic>)
        (payload['data'] as Map<String, dynamic>)['token'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _extractUser(Map<String, dynamic> payload) {
    final directUser = payload['user'];
    if (directUser is Map<String, dynamic>) return directUser;

    final dataUser = payload['data'];
    if (dataUser is Map<String, dynamic>) {
      final nestedUser = dataUser['user'];
      if (nestedUser is Map<String, dynamic>) {
        return nestedUser;
      }
    }

    final profile = payload['profile'];
    if (profile is Map<String, dynamic>) {
      return profile;
    }

    return null;
  }

  static String? _firstNonEmpty(
      Map<String, dynamic>? source, List<String> potentialKeys) {
    if (source == null) return null;
    for (final key in potentialKeys) {
      final value = source[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
