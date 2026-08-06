/// Backend endpoints.
///
/// Tracked in git on purpose — unlike `api_config.dart`, a base URL is not a
/// secret, and a fresh clone must still know where the API lives.
///
/// This used to be copy-pasted into six services, which is how five of them
/// ended up on a different host from `ChatService`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://tripnestbackend-v2.onrender.com/api';
}
