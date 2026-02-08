import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/chat_service.dart';
import 'chat_thread_page.dart';

// Global notifier for unread message count
class MessageNotifier extends ChangeNotifier {
  static final MessageNotifier _instance = MessageNotifier._internal();
  factory MessageNotifier() => _instance;
  MessageNotifier._internal();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Callback for showing banner
  void Function(String roomName, String message)? onNewMessage;

  void setUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  void showNewMessageBanner(String roomName, String message) {
    onNewMessage?.call(roomName, message);
  }

  void clearUnread() {
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  int _lastKnownMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLastKnownCount();
    _loadChatRooms();
    // Auto-refresh every 5 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshChatRooms();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLastKnownCount() async {
    final prefs = await SharedPreferences.getInstance();
    _lastKnownMessageCount = prefs.getInt('last_known_message_count') ?? 0;
  }

  Future<void> _saveLastKnownCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_known_message_count', count);
    _lastKnownMessageCount = count;
  }

  // Calculate total messages across all rooms
  int _getTotalMessageCount(List<ChatRoom> rooms) {
    int total = 0;
    for (final room in rooms) {
      if (room.lastMessage != null) {
        // Use a hash of room id + last message id to track changes
        total += room.lastMessage!.id.hashCode;
      }
    }
    return total;
  }

  // Silent refresh without showing loading indicator
  Future<void> _refreshChatRooms() async {
    if (!mounted) return;
    try {
      final rooms = await ChatService.getChatRooms();
      if (!mounted) return;
      
      final currentCount = _getTotalMessageCount(rooms);
      
      // Check if there are new messages
      if (currentCount != _lastKnownMessageCount && _lastKnownMessageCount != 0) {
        // New messages arrived - update the notification count
        MessageNotifier().setUnreadCount(1);
        
        // Find the room with the new message and show banner
        for (final room in rooms) {
          if (room.lastMessage != null) {
            // Show banner for the latest message
            MessageNotifier().showNewMessageBanner(
              room.eventTitle,
              '${room.lastMessage!.senderName}: ${room.lastMessage!.content}',
            );
            break; // Show only one banner
          }
        }
      }
      
      setState(() {
        _chatRooms = rooms;
        _errorMessage = null;
      });
    } catch (e) {
      // Silent fail on auto-refresh to avoid disrupting the user
      debugPrint('Auto-refresh error: $e');
    }
  }

  // Mark messages as read when viewing
  void _markAsRead() {
    final currentCount = _getTotalMessageCount(_chatRooms);
    _saveLastKnownCount(currentCount);
    MessageNotifier().clearUnread();
  }

  Future<void> _loadChatRooms() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rooms = await ChatService.getChatRooms();
      if (!mounted) return;
      
      final currentCount = _getTotalMessageCount(rooms);
      
      // If first load, save the count
      if (_lastKnownMessageCount == 0) {
        _saveLastKnownCount(currentCount);
      }
      
      setState(() {
        _chatRooms = rooms;
        _isLoading = false;
      });
      
      // Mark as read since user is viewing
      _markAsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    // Format as date
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search or start new chat',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
          ),
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
                            Text('Error loading messages',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(_errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadChatRooms,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _chatRooms.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mail_outline,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No messages yet'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadChatRooms,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _chatRooms.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final room = _chatRooms[index];
                                return _chatCell(
                                  context,
                                  name: room.eventTitle,
                                  last: room.lastMessage != null
                                      ? '${room.lastMessage!.senderName}: ${room.lastMessage!.content}'
                                      : 'No messages',
                                  time: room.lastMessage != null
                                      ? _formatTime(room.lastMessage!.createdAt)
                                      : '',
                                  roomId: room.id,
                                  imageUrl: room.eventImageUrl,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatThreadPage(
                                        roomId: room.id,
                                        roomName: room.eventTitle,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chatCell(
    BuildContext context, {
    required String name,
    required String last,
    required String time,
    required String roomId,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2563EB),
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(time,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 6),
            ]),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
