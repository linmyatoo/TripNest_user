import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'core/services/chat_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_colors.dart';
import 'features/booking/my_booking_page.dart';
import 'features/favorites/favorites_page.dart';
import 'features/home/home_page.dart';
import 'features/messages/messages_page.dart';
import 'features/profile/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int idx;

  // Key to force rebuild favorites page when tab is selected
  int _favoritesRebuildKey = 0;

  // For draggable chatbot button
  Offset _chatbotOffset = const Offset(20, 500);
  Size? _screenSize;

  // Message notifier for badge
  final _messageNotifier = MessageNotifier();
  
  // Timer for checking new messages at AppShell level
  Timer? _messageCheckTimer;
  Map<String, String> _lastKnownMessageIds = {}; // roomId -> lastMessageId

  @override
  void initState() {
    super.initState();
    idx = widget.initialIndex;
    _messageNotifier.addListener(_onMessageCountChanged);
    // Start checking for new messages every 5 seconds
    _loadLastKnownMessageIds();
    _messageCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkForNewMessages();
    });
  }

  @override
  void dispose() {
    _messageCheckTimer?.cancel();
    _messageNotifier.removeListener(_onMessageCountChanged);
    super.dispose();
  }

  Future<void> _loadLastKnownMessageIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('shell_last_message_ids') ?? [];
    _lastKnownMessageIds = {};
    for (final entry in stored) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        _lastKnownMessageIds[parts[0]] = parts[1];
      }
    }
  }

  Future<void> _saveLastKnownMessageIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _lastKnownMessageIds.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();
    await prefs.setStringList('shell_last_message_ids', list);
  }

  Future<void> _checkForNewMessages() async {
    if (!mounted) return;
    try {
      final rooms = await ChatService.getChatRooms();
      if (!mounted) return;
      
      // First time - just save all message IDs
      if (_lastKnownMessageIds.isEmpty) {
        for (final room in rooms) {
          if (room.lastMessage != null) {
            _lastKnownMessageIds[room.id] = room.lastMessage!.id;
          }
        }
        _saveLastKnownMessageIds();
        return;
      }
      
      // Check each room for new messages
      bool hasNewMessages = false;
      for (final room in rooms) {
        if (room.lastMessage != null) {
          final lastKnownId = _lastKnownMessageIds[room.id];
          final currentId = room.lastMessage!.id;
          
          // New message in this room
          if (lastKnownId != currentId) {
            hasNewMessages = true;
            
            final senderName = room.lastMessage!.senderName;
            final messageContent = room.lastMessage!.content;
            
            // Show system notification with correct room info
            LocalNotificationService.showMessageNotification(
              senderName: room.eventTitle,
              message: '$senderName: $messageContent',
              roomId: room.id,
              roomName: room.eventTitle,
            );
            
            // Update the tracked ID for this room
            _lastKnownMessageIds[room.id] = currentId;
            break; // Only show one notification at a time
          }
        }
      }
      
      if (hasNewMessages) {
        _messageNotifier.setUnreadCount(1);
        _saveLastKnownMessageIds();
      }
    } catch (e) {
      debugPrint('Error checking for new messages: $e');
    }
  }

  void _onMessageCountChanged() {
    if (mounted) setState(() {});
  }

  void _onTabSelected(int i) {
    // If switching to favorites tab, force rebuild to refresh data
    if (i == 2) {
      _favoritesRebuildKey++;
    }
    // If switching to messages tab, clear unread badge
    if (i == 3) {
      _messageNotifier.clearUnread();
    }
    setState(() => idx = i);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for edge snapping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_screenSize == null && context.mounted) {
        final size = MediaQuery.of(context).size;
        setState(() => _screenSize = size);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: idx,
            children: [
              const HomePage(),
              const MyBookingPage(),
              FavoritesPage(key: ValueKey(_favoritesRebuildKey)),
              const MessagesPage(),
              const ProfilePage(),
            ],
          ),
          // Draggable chatbot button - appears over bottom bar
          if (_screenSize != null)
            Positioned(
              left: _chatbotOffset.dx,
              top: _chatbotOffset.dy,
              child: Draggable(
                feedback: _chatbotFab(context, dragging: true),
                childWhenDragging: const SizedBox.shrink(),
                onDragEnd: (details) {
                  final size = _screenSize!;
                  const btnSize = 56.0;
                  double x = details.offset.dx;
                  double y =
                      details.offset.dy - MediaQuery.of(context).padding.top;
                  // Snap to left or right edge
                  if (x + btnSize / 2 < size.width / 2) {
                    x = 10;
                  } else {
                    x = size.width - btnSize - 10;
                  }
                  // Clamp y - allow it to go near the bottom (over the nav bar area)
                  y = y.clamp(10.0, size.height - btnSize - 100.0);
                  setState(() {
                    _chatbotOffset = Offset(x, y);
                  });
                },
                child: GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.chatbot),
                  child: _chatbotFab(context),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: .12),
        selectedIndex: idx,
        onDestinationSelected: _onTabSelected,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'My Booking'),
          const NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorite'),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: _messageNotifier.unreadCount > 0,
                child: const Icon(Icons.message_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: _messageNotifier.unreadCount > 0,
                child: const Icon(Icons.message),
              ),
              label: 'Message'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'My Profile'),
        ],
      ),
    );
  }

  Widget _chatbotFab(BuildContext context, {bool dragging = false}) {
    return Opacity(
      opacity: dragging ? 0.7 : 1.0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF2563EB),
              Color(0xFF1D4ED8),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.flutter_dash,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
