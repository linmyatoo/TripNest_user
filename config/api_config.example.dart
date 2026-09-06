// Template for lib/src/core/config/api_config.dart, which is git-ignored.
//
// Setup:
//   cp config/api_config.example.dart lib/src/core/config/api_config.dart
// then fill in the real keys.
//
// This file lives outside lib/ on purpose so it is never compiled into the app
// and can never be imported by mistake.

/// API keys and endpoints.
class ApiConfig {
  ApiConfig._();

  // --- Groq (https://console.groq.com) - OpenAI-compatible ---
  static const String chatApiKey = 'PASTE_YOUR_GROQ_API_KEY_HERE';
  static const String chatBaseUrl = 'https://api.groq.com/openai/v1';
  static const String chatModel = 'openai/gpt-oss-120b';
  static const double chatTemperature = 0.7;
  static const double chatTopP = 0.9;
  static const int chatMaxTokens = 1024;

  // --- WAQI air quality (https://aqicn.org/data-platform/token/) ---
  static const String waqiApiToken = 'PASTE_YOUR_WAQI_TOKEN_HERE';
  static const String waqiBaseUrl = 'https://api.waqi.info/feed';

  /// True when the WAQI token is still a placeholder.
  static bool get isWaqiTokenMissing =>
      waqiApiToken.isEmpty || waqiApiToken.startsWith('PASTE_YOUR_');

  static Uri get chatCompletionsUrl =>
      Uri.parse('$chatBaseUrl/chat/completions');

  /// True when the chat key is still a placeholder.
  static bool get isChatKeyMissing =>
      chatApiKey.isEmpty || chatApiKey.startsWith('PASTE_YOUR_');
}
