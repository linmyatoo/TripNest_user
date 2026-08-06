import 'package:flutter/foundation.dart';

/// Debug-only logger.
///
/// Everything routed through here is dropped in release builds, unlike `print`,
/// which keeps writing to the device log (`adb logcat`) in a shipped app.
///
/// Never pass passwords, tokens, or raw response bodies to these methods — the
/// reason logs go through one place is so nothing sensitive can leak. Log the
/// status code and the endpoint, not the payload.
class AppLog {
  AppLog._();

  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static void e(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint(error == null ? message : '$message: $error');
    }
  }

  /// Renders a sensitive value as a length hint only, e.g. `<set:32>`.
  static String redact(Object? value) {
    if (value == null) return '<null>';
    final text = value.toString();
    return text.isEmpty ? '<empty>' : '<set:${text.length}>';
  }
}
