// Template for lib/src/core/config/api_config.dart, which is git-ignored.
//
// Setup:
//   cp config/api_config.example.dart lib/src/core/config/api_config.dart
// then fill in the real keys.
//
// This file lives outside lib/ on purpose so it is never compiled into the app
// and can never be imported by mistake.

/// Which chat provider the chatbot talks to.
enum ChatProvider { groq, grok }

/// API keys and endpoints.
class ApiConfig {
  ApiConfig._();

  /// Provider used by [ChatbotPage]. Switch to [ChatProvider.grok] for xAI.
  static const ChatProvider chatProvider = ChatProvider.groq;

  // --- xAI Grok (https://console.x.ai) - OpenAI-compatible ---
  static const String grokApiKey = 'PASTE_YOUR_XAI_API_KEY_HERE';
  static const String grokBaseUrl = 'https://api.x.ai/v1';
  static const String grokModel = 'grok-4.5';

  // --- Groq (https://console.groq.com) - OpenAI-compatible ---
  static const String groqApiKey = 'PASTE_YOUR_GROQ_API_KEY_HERE';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.3-70b-versatile';

  // --- WAQI air quality (https://aqicn.org/data-platform/token/) ---
  static const String waqiApiToken = 'PASTE_YOUR_WAQI_TOKEN_HERE';
  static const String waqiBaseUrl = 'https://api.waqi.info/feed';

  /// True when the WAQI token is still a placeholder.
  static bool get isWaqiTokenMissing =>
      waqiApiToken.isEmpty || waqiApiToken.startsWith('PASTE_YOUR_');

  static String get chatApiKey => switch (chatProvider) {
        ChatProvider.grok => grokApiKey,
        ChatProvider.groq => groqApiKey,
      };

  static String get chatModel => switch (chatProvider) {
        ChatProvider.grok => grokModel,
        ChatProvider.groq => groqModel,
      };

  static String get chatBaseUrl => switch (chatProvider) {
        ChatProvider.grok => grokBaseUrl,
        ChatProvider.groq => groqBaseUrl,
      };

  static Uri get chatCompletionsUrl =>
      Uri.parse('$chatBaseUrl/chat/completions');

  /// True when the selected provider still has a placeholder key.
  static bool get isChatKeyMissing =>
      chatApiKey.isEmpty || chatApiKey.startsWith('PASTE_YOUR_');
}
