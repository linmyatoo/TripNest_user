import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

/// The single HTTP client every service goes through.
///
/// Services used to call the top-level `http.get`/`http.post` helpers, which
/// are impossible to intercept — so nothing that touched the network could be
/// tested. Routing through here lets a test swap in `MockClient`.
class Http {
  Http._();

  static http.Client _client = http.Client();

  static http.Client get client => _client;

  /// Replaces the client (tests only). Call [reset] afterwards.
  @visibleForTesting
  static void overrideClient(http.Client client) => _client = client;

  @visibleForTesting
  static void reset() => _client = http.Client();
}
