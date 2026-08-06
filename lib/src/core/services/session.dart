import 'package:http/http.dart' as http;

import '../../../main.dart' show navigatorKey;
import '../utils/app_log.dart';
import 'auth_service.dart';

/// Thrown when the backend rejects the stored token.
class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Your session has expired.']);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

/// Single place that reacts to an expired or revoked token.
///
/// Before this existed, a 401 surfaced as a generic "Network error" on every
/// screen and left the user stuck inside an app they were no longer
/// authenticated for, with no route back to login.
class Session {
  Session._();

  static bool _expiring = false;

  /// Throws [UnauthorizedException] on a 401 and kicks off the sign-out.
  ///
  /// Call this right after every authenticated request, before parsing.
  /// Deliberately does not treat 403 as expiry — the chat API uses 403 for
  /// "you are not a member of this room", which is a business rule, not a
  /// dead token.
  static void checkResponse(http.Response response) {
    if (response.statusCode == 401) {
      expire();
      throw const UnauthorizedException();
    }
  }

  /// Clear the session and send the user back to login. Idempotent: several
  /// in-flight requests can each see a 401 without stacking navigations.
  static Future<void> expire() async {
    if (_expiring) return;
    _expiring = true;
    try {
      await AuthService.logout();
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        await navigator.pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      AppLog.e('Session expiry handling failed', e);
    } finally {
      _expiring = false;
    }
  }
}
