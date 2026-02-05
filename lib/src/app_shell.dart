import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/home/home_page.dart';
import 'features/booking/my_booking_page.dart';
import 'features/favorites/favorites_page.dart';
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
    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: [
          const HomePage(),
          const MyBookingPage(),
          FavoritesPage(key: ValueKey(_favoritesRebuildKey)),
          const MessagesPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(.12),
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
}
