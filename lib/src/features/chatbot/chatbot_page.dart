import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/services/http_client.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toApiMessage() {
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': text,
    };
  }
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  /// How many past turns to replay to the model on each request.
  static const int _maxHistoryMessages = 20;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final String _systemPrompt =
      '''You are TripNest Assistant, a friendly and helpful AI travel companion. 
You help users discover amazing events, find travel recommendations, plan trips, and answer questions about TripNest app features.

Key features of TripNest:
- Browse and book events and festivals
- Find travel recommendations
- Save favorites
- Manage bookings
- Get personalized suggestions

Be concise, friendly, and use emojis occasionally to keep the conversation engaging. 
Always be helpful and provide actionable advice when possible.''';

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text:
          "Hi! 👋 I'm your TripNest AI assistant. I can help you find events, plan trips, and discover new experiences. What would you like to explore today?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final response = await _callChatApi();
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "Sorry, I encountered an error. Please try again.",
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }

  Future<String> _callChatApi() async {
    if (ApiConfig.isChatKeyMissing) {
      throw Exception('Missing API key for ${ApiConfig.chatProvider.name}');
    }

    // _messages already ends with this turn (added by _sendMessage), so it must
    // not be appended again. Only the tail is sent so a long session can't grow
    // past the model's context window.
    final history = _messages.length > _maxHistoryMessages
        ? _messages.sublist(_messages.length - _maxHistoryMessages)
        : _messages;

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => m.toApiMessage()),
    ];

    final response = await Http.client.post(
      ApiConfig.chatCompletionsUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.chatApiKey}',
      },
      body: jsonEncode({
        'model': ApiConfig.chatModel,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TripNest AI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text:
                      "Hi! 👋 I'm your TripNest AI assistant. I can help you find events, plan trips, and discover new experiences. What would you like to explore today?",
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: '',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      enabled: !_isTyping,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isTyping
                      ? null
                      : () => _sendMessage(_inputController.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isTyping
                          ? Colors.grey.shade300
                          : const Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 9, 43, 213),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flutter_dash,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF007AFF) : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF4ECDC4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8E8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3 + opacity * 0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
