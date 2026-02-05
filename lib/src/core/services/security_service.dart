import 'dart:convert';

import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Storage keys
  static const String _rememberPasswordKey = 'remember_password';
  static const String _faceIdEnabledKey = 'face_id_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // ==================== Settings ====================

  /// Get remember password setting
  static Future<bool> isRememberPasswordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberPasswordKey) ?? false;
  }

  /// Set remember password setting
  static Future<void> setRememberPassword(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberPasswordKey, enabled);

    // If disabled, clear saved credentials
    if (!enabled) {
      await clearSavedCredentials();
    }
  }

  /// Get Face ID setting
  static Future<bool> isFaceIdEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceIdEnabledKey) ?? false;
  }

  /// Set Face ID setting
  static Future<void> setFaceIdEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceIdEnabledKey, enabled);
  }

  /// Get Biometric ID setting
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Set Biometric ID setting
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  // ==================== Credentials ====================

  /// Save login credentials (only if remember password is enabled)
  static Future<void> saveCredentials(String email, String password) async {
    final rememberEnabled = await isRememberPasswordEnabled();
    if (!rememberEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    // Simple base64 encoding for basic obfuscation (not true encryption)
    final encodedPassword = base64Encode(utf8.encode(password));
    await prefs.setString(_savedEmailKey, email);
    await prefs.setString(_savedPasswordKey, encodedPassword);
  }

  /// Get saved email
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedEmailKey);
  }

  /// Get saved password
  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPassword = prefs.getString(_savedPasswordKey);
    if (encodedPassword == null) return null;

    try {
      return utf8.decode(base64Decode(encodedPassword));
    } catch (_) {
      return null;
    }
  }

  /// Check if credentials are saved
  static Future<bool> hasStoredCredentials() async {
    final email = await getSavedEmail();
    final password = await getSavedPassword();
    return email != null &&
        password != null &&
        email.isNotEmpty &&
        password.isNotEmpty;
  }

  /// Clear saved credentials
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
  }

  // ==================== Biometric Authentication ====================

  /// Check if device supports biometric authentication
  static Future<bool> isBiometricSupported() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Check if Face ID is available
  static Future<bool> isFaceIdAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if fingerprint is available
  static Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics(
      {String reason = 'Please authenticate to login'}) async {
    try {
      final isSupported = await isBiometricSupported();
      if (!isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  /// Check if biometric login is available and enabled
  static Future<bool> canUseBiometricLogin() async {
    final faceIdEnabled = await isFaceIdEnabled();
    final biometricEnabled = await isBiometricEnabled();
    final hasCredentials = await hasStoredCredentials();
    final isSupported = await isBiometricSupported();

    return (faceIdEnabled || biometricEnabled) && hasCredentials && isSupported;
  }

  // ==================== Clear All ====================

  /// Clear all security settings (for logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep the settings but clear credentials
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
  }
}
