import '../services/auth_service.dart';

/// Helper class for common auth operations
class AuthHelper {
  /// Get current user's ID
  static Future<String?> getCurrentUserId() async {
    return await AuthService.getUserId();
  }

  /// Get current user's token
  static Future<String?> getCurrentToken() async {
    return await AuthService.getToken();
  }

  /// Get all current user data
  static Future<Map<String, String?>> getCurrentUser() async {
    return await AuthService.getUserData();
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await AuthService.isLoggedIn();
  }

  /// Logout current user
  static Future<void> logoutUser() async {
    await AuthService.logout();
  }

  /// Get authorization header for API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getCurrentToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
