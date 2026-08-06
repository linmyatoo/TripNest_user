import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import 'messages_page.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });
  final String roomId;
  final String roomName;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final msgCtrl = TextEditingController();
  late final ScrollController _scrollController;
  List<Message> _messages = [];
  List<Member> _members = [];
  bool _isLoading = false;
  bool _isMembersLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;
  String _currentUserName = 'You';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeChat();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshMessages() async {
    if (!mounted || _isSending) return;
    try {
      final messages = await ChatService.getChatMessages(widget.roomId);
      if (!mounted) return;

      if (messages.length != _messages.length) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Auto-refresh messages error: $e');
    }
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

  Future<void> _initializeChat() async {
    MessageNotifier().clearUnread();
    await _loadCurrentUser();
    await _loadMessages();
    await _loadMembers();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.getUserId();
      final profileData = await AuthService.getProfileMe();

      final user = profileData['data'] ?? profileData['user'] ?? profileData;

      debugPrint('=== DEBUG: User data keys: ${user.keys.toList()}');
      debugPrint('=== DEBUG: Local userId from SharedPrefs: $userId');

      String? apiUserId;
      if (user['userId'] != null) {
        apiUserId = user['userId'].toString();
      } else if (user['id'] != null) {
        apiUserId = user['id'].toString();
      } else if (user['_id'] != null) {
        apiUserId = user['_id'].toString();
      }

      debugPrint('=== DEBUG: Extracted apiUserId: $apiUserId');

      String username = 'You';
      if (user['fullName'] != null &&
          user['fullName'].toString().isNotEmpty &&
          user['fullName'] != 'Not Set') {
        username = user['fullName'];
      } else if (user['name'] != null &&
          user['name'].toString().isNotEmpty) {
        username = user['name'];
      } else if (user['username'] != null &&
          user['username'].toString().isNotEmpty) {
        username = user['username'];
      }

      if (mounted) {
        setState(() {
          _currentUserId = apiUserId ?? userId;
          debugPrint('=== DEBUG: Final _currentUserId set to: $_currentUserId');
          _currentUserName = username;
        });
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await ChatService.getChatMessages(widget.roomId);
      if (!mounted) return;

      try {
        final currentUserMessage =
            messages.firstWhere((msg) => msg.senderId == _currentUserId);
        if (currentUserMessage.senderName.isNotEmpty &&
            currentUserMessage.senderName != 'Unknown') {
          setState(() {
            _currentUserName = currentUserMessage.senderName;
          });
        }
      } catch (e) {
        // No messages from current user found
      }

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() {
      _isMembersLoading = true;
    });

    try {
      final members = await ChatService.getChatMembers(widget.roomId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _isMembersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading members: $e');
      setState(() {
        _isMembersLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = msgCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSending = true;
    });

    try {
      final sentMessage = await ChatService.sendMessage(widget.roomId, content);
      if (!mounted) return;

      if (_currentUserId != sentMessage.senderId) {
        _currentUserId = sentMessage.senderId;
      }

      final messageWithName = Message(
        id: sentMessage.id,
        senderId: sentMessage.senderId,
        senderName: _currentUserName,
        senderEmail: sentMessage.senderEmail,
        content: sentMessage.content,
        createdAt: sentMessage.createdAt,
      );

      setState(() {
        _messages.add(messageWithName);
        _isSending = false;
      });
      _scrollToBottom();

      msgCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showMembersBottomSheet(),
            icon: const Icon(Icons.more_horiz),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadMessages,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No messages yet'),
                                SizedBox(height: 4),
                                Text('Start the conversation!',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMine = msg.senderId.toString() ==
                                  _currentUserId.toString();
                              if (index == 0) {
                                debugPrint(
                                    '=== DEBUG: First msg.senderId: "${msg.senderId}"');
                                debugPrint(
                                    '=== DEBUG: _currentUserId: "$_currentUserId"');
                                debugPrint(
                                    '=== DEBUG: isMine result: $isMine');
                              }
                              return _MessageBubble(
                                message: msg,
                                isMe: isMine,
                                time: _formatTime(msg.createdAt),
                              );
                            },
                          ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members (${_members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isMembersLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _members.isEmpty
                      ? const Center(child: Text('No members found'))
                      : ListView.separated(
                          controller: controller,
                          itemCount: _members.length,
                          separatorBuilder: (context, index) =>
                              const Divider(),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final isCurrent =
                                member.userId == _currentUserId;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  // An empty name would throw a RangeError
                                  // here; the message list already guards it.
                                  member.userName.isNotEmpty
                                      ? member.userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(member.userName),
                              trailing: isCurrent
                                  ? const Chip(
                                      label: Text('You'),
                                      backgroundColor:
                                          Color.fromARGB(255, 183, 197, 226),
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 40,
              right: isMe ? 4 : 0,
            ),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}