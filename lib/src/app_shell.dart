import 'package:flutter/material.dart';

import 'app_router.dart';
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

  @override
  void initState() {
    super.initState();
    idx = widget.initialIndex;
  }

  void _onTabSelected(int i) {
    // If switching to favorites tab, force rebuild to refresh data
    if (i == 2) {
      _favoritesRebuildKey++;
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
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'My Booking'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorite'),
          NavigationDestination(
              icon: Icon(Icons.message_outlined),
              selectedIcon: Icon(Icons.message),
              label: 'Message'),
          NavigationDestination(
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
