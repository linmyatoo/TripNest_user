import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_log.dart';

/// Result of a biometric authentication attempt.
enum BiometricResult {
  success,

  /// User cancelled, or the prompt was dismissed.
  cancelled,

  /// Wrong finger/face, too many attempts, or hardware temporarily locked out.
  failed,

  /// No usable biometric hardware, or nothing enrolled.
  unavailable,
}

class SecurityService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Credentials live in the Keychain / Android Keystore, never in
  /// SharedPreferences: prefs are plaintext on disk and get swept into
  /// unencrypted device backups.
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

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

    await _secureStorage.write(key: _savedEmailKey, value: email);
    await _secureStorage.write(key: _savedPasswordKey, value: password);
  }

  /// Get saved email
  static Future<String?> getSavedEmail() async {
    try {
      return await _secureStorage.read(key: _savedEmailKey);
    } on PlatformException catch (e) {
      AppLog.e('Secure storage read failed (email)', e);
      return null;
    }
  }

  /// Get saved password
  static Future<String?> getSavedPassword() async {
    try {
      return await _secureStorage.read(key: _savedPasswordKey);
    } on PlatformException catch (e) {
      AppLog.e('Secure storage read failed (password)', e);
      return null;
    }
  }

  /// Replace the stored password after a successful password change, so
  /// prefill and biometric login stop replaying the old one.
  static Future<void> updateSavedPassword(String newPassword) async {
    final existingEmail = await getSavedEmail();
    if (existingEmail == null) return;
    await _secureStorage.write(key: _savedPasswordKey, value: newPassword);
  }

  /// One-time migration of the old base64-in-SharedPreferences credentials
  /// into secure storage. Safe to call on every startup.
  static Future<void> migrateLegacyCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyEmail = prefs.getString(_savedEmailKey);
    final legacyPassword = prefs.getString(_savedPasswordKey);
    if (legacyEmail == null && legacyPassword == null) return;

    try {
      if (legacyEmail != null && legacyEmail.isNotEmpty) {
        await _secureStorage.write(key: _savedEmailKey, value: legacyEmail);
      }
      if (legacyPassword != null && legacyPassword.isNotEmpty) {
        // Legacy values were base64(utf8(password)).
        final decoded = utf8.decode(base64Decode(legacyPassword));
        await _secureStorage.write(key: _savedPasswordKey, value: decoded);
      }
    } catch (e) {
      AppLog.e('Legacy credential migration failed', e);
    } finally {
      // Remove the plaintext copies regardless: leaving them behind defeats
      // the point of migrating.
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
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
    await _secureStorage.delete(key: _savedEmailKey);
    await _secureStorage.delete(key: _savedPasswordKey);
    // Also drop anything left over from the pre-migration plaintext storage.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
  }

  // ==================== Biometric Authentication ====================

  /// Check if the device can actually do biometrics *and* has something
  /// enrolled. `isDeviceSupported()` alone is true for a device-PIN-only
  /// setup, which is not what "Face ID login" promises the user.
  static Future<bool> isBiometricSupported() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
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

  /// Authenticate with biometrics.
  ///
  /// `biometricOnly: true` matters: with the default (false), a device PIN or
  /// pattern satisfies the prompt, so "Face ID login" would accept a 4-digit
  /// PIN from anyone holding the phone.
  ///
  /// `persistAcrossBackgrounding: true` retries after the OS backgrounds the
  /// app mid-prompt (the 3.x name for the old `stickyAuth`), instead of
  /// failing the attempt.
  static Future<BiometricResult> authenticate(
      {String reason = 'Please authenticate to login'}) async {
    if (!await isBiometricSupported()) return BiometricResult.unavailable;

    try {
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (e) {
      AppLog.e('Biometric authentication failed (${e.code.name})');
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
        case LocalAuthExceptionCode.userRequestedFallback:
          return BiometricResult.cancelled;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        case LocalAuthExceptionCode.uiUnavailable:
          return BiometricResult.unavailable;
        default:
          // temporaryLockout, biometricLockout, authInProgress, deviceError,
          // unknownError: all "try again / fall back to password".
          return BiometricResult.failed;
      }
    } catch (e) {
      AppLog.e('Biometric authentication failed', e);
      return BiometricResult.failed;
    }
  }

  /// Backwards-compatible boolean wrapper.
  static Future<bool> authenticateWithBiometrics(
      {String reason = 'Please authenticate to login'}) async {
    return await authenticate(reason: reason) == BiometricResult.success;
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

  /// Clear all security settings (keeps the toggles, drops credentials)
  static Future<void> clearAll() => clearSavedCredentials();
}
