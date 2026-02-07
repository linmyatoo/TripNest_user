import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://naylinhtet.me/api';

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
    final response = await http.post(
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

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nameKey);
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

      print('Registering user at: $url');
      print('Request body: ${jsonEncode({
            'name': username,
            'phone_number': phone_number,
            'email': email,
            'password': password,
            'role': role,
          })}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': username,
          'phone_number': phone_number,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful
        return data;
      } else {
        // Registration failed
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
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
          print('Login succeeded but no token was found in the response.');
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

      final response = await http.get(
        Uri.parse('$baseUrl/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=================================');
      print('PROFILE ME RESPONSE');
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

      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=================================');
      print('PROFILE BY ID RESPONSE');
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

      print('=================================');
      print('UPLOADING PROFILE IMAGE');
      print('File path: $filePath');
      print('Endpoint: $uri');
      print('=================================');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload Response Status: ${response.statusCode}');
      print('Upload Response Body: ${response.body}');

      // Handle empty response
      if (response.body.isEmpty) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Upload successful but no URL returned');
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
          print('Server returned non-JSON response: ${response.body}');
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
      print('Image upload error: $e');
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

      final response = await http.patch(
        Uri.parse('$baseUrl/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('=================================');
      print('UPDATE PROFILE RESPONSE');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=================================');

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
        print('JSON Parse Error: $e');
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

    print('=================================');
    print('UPDATE PROFILE WITH IMAGE');
    print('File path: $imageFilePath');
    print('Content-Type: $contentType');
    print('Field name: profilePicture');
    print('Fields: ${request.fields}');
    print('=================================');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

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
      print('JSON Parse Error: $e');
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

  /// Forgot password - sends reset link to email
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      print('=================================');
      print('FORGOT PASSWORD RESPONSE');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=================================');

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
        print('JSON Parse Error: $e');

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
      print('Format Exception: $e');
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
