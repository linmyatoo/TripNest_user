import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/chat_service.dart';
import 'chat_thread_page.dart';
import '../../core/theme/app_colors.dart';

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
  int _lastKnownMessageCount = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLastKnownCount();
    _loadChatRooms();
    // Refreshes when the shell's poller reports new messages, plus pull-to-
    // refresh. This page used to run its own 5s timer on top of the shell's,
    // and it kept firing while the tab was hidden inside the IndexedStack.
    MessageNotifier().addListener(_onUnreadChanged);
  }

  void _onUnreadChanged() {
    if (!mounted) return;
    if (MessageNotifier().unreadCount > 0) _refreshChatRooms();
  }

  @override
  void dispose() {
    MessageNotifier().removeListener(_onUnreadChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Rooms matching the search box. The field used to have no controller at
  /// all, so typing in it did nothing.
  List<ChatRoom> get _visibleRooms {
    if (_searchQuery.isEmpty) return _chatRooms;
    final query = _searchQuery.toLowerCase();
    return _chatRooms.where((room) {
      final title = room.eventTitle.toLowerCase();
      final lastMessage = room.lastMessage?.content.toLowerCase() ?? '';
      final sender = room.lastMessage?.senderName.toLowerCase() ?? '';
      return title.contains(query) ||
          lastMessage.contains(query) ||
          sender.contains(query);
    }).toList();
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
      final rooms = await ChatService.getBookedChatRooms();
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
      final rooms = await ChatService.getBookedChatRooms();
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

  /// Ask, then leave. Returns true only when the room is actually gone, and
  /// removes it by id so a concurrent refresh can't shift indices underneath.
  Future<bool> _confirmLeaveRoom(ChatRoom room) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Chat Room'),
        content: const Text('Are you sure you want to leave this chat room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldLeave != true) return false;

    try {
      await ChatService.leaveChatRoom(room.id);
      if (!mounted) return false;
      setState(() {
        _chatRooms.removeWhere((r) => r.id == room.id);
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('not a member')
                ? 'You are not a member of this chat room.'
                : 'Failed to leave chat room.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
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
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search your chat',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
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
                    : _visibleRooms.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.mail_outline,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(_searchQuery.isEmpty
                                    ? 'No messages yet'
                                    : 'No chats match "$_searchQuery"'),
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 6),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      'Book an event to join its chat.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadChatRooms,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _visibleRooms.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final room = _visibleRooms[index];
                                return Dismissible(
                                  key: ValueKey(room.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.exit_to_app, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Leave Chat Room',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            )),
                                      ],
                                    ),
                                  ),
                                  // The leave request runs inside
                                  // confirmDismiss, not onDismissed: a failed
                                  // request must return false so the row stays
                                  // in the tree. Dismissing a row whose item is
                                  // still in the list throws.
                                  confirmDismiss: (direction) =>
                                      _confirmLeaveRoom(room),
                                  child: _chatCell(
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
              backgroundColor: AppColors.primary,
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
