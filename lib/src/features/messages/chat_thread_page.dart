import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeChat();
  }

  @override
  void dispose() {
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

  Future<void> _initializeChat() async {
    await _loadCurrentUser();
    await _loadMessages();
    await _loadMembers();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.getUserId();
      final profileData = await AuthService.getProfileMe();

      // Extract username from profile response
      String username = 'You';
      if (profileData['name'] != null &&
          profileData['name'].toString().isNotEmpty) {
        username = profileData['name'];
      } else if (profileData['username'] != null &&
          profileData['username'].toString().isNotEmpty) {
        username = profileData['username'];
      }

      if (mounted) {
        setState(() {
          _currentUserId = userId;
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

      // Extract current user's name from messages
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

      // Create a new message with the current user's info
      final messageWithName = Message(
        id: sentMessage.id,
        senderId: _currentUserId ?? sentMessage.senderId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.roomName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const Text('Online',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
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
                            const Text('Error loading messages'),
                            const SizedBox(height: 8),
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
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMine = msg.senderId == _currentUserId;
                              return _Bubble(
                                text: msg.content,
                                time: _formatTime(msg.createdAt),
                                senderName: msg.senderName,
                                mine: isMine,
                              );
                            },
                          ),
          ),
          // composer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file_outlined)),
                  Expanded(
                    child: TextField(
                      controller: msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Write a reply',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _isSending ? null : _sendMessage,
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }

    return '${dateTime.month}/${dateTime.day}';
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
            // Header
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
            // Members List
            Expanded(
              child: _isMembersLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _members.isEmpty
                      ? const Center(child: Text('No members found'))
                      : ListView.separated(
                          controller: controller,
                          itemCount: _members.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final isCurrent = member.userId == _currentUserId;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  member.userName[0].toUpperCase(),
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

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.time,
    required this.mine,
    this.senderName,
  });

  final String text;
  final String time;
  final bool mine;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final color = mine ? const Color(0xFF2563EB) : const Color(0xFFF2F4F7);
    final textColor = mine ? Colors.white : Colors.black87;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft:
                mine ? const Radius.circular(14) : const Radius.circular(0),
            bottomRight:
                mine ? const Radius.circular(0) : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderName != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[400],
                    child: Text(
                      senderName![0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    senderName!,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (senderName != null) const SizedBox(height: 4),
            Text(text, style: TextStyle(color: textColor)),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    color: textColor.withValues(alpha: .8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
