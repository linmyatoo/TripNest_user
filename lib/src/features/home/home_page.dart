import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/app_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/event_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/event.dart';
import '../../widgets/event_card.dart';
import '../notifications/notification_feed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Event> _popularEvents = [];
  List<Event> _upcomingEvents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _displayName = 'Traveler';
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadEvents();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) return;

      final bookings = await BookingService.getMyBookings();
      final prefs = await SharedPreferences.getInstance();
      final lastReadCount = prefs.getInt('last_read_notification_count') ?? 0;

      if (!mounted) return;
      setState(() {
        // Show unread dot if there are new bookings since last read
        _unreadNotificationCount = bookings.length - lastReadCount;
        if (_unreadNotificationCount < 0) _unreadNotificationCount = 0;
      });
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final bookings = await BookingService.getMyBookings();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_read_notification_count', bookings.length);

      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = 0;
      });
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      // First try to get name from API
      final profileData = await AuthService.getProfileMe();
      debugPrint('Profile data: $profileData');
      if (mounted) {
        // Try different field names that might contain the user's name
        final name = profileData['fullName'] as String? ??
            profileData['full_name'] as String? ??
            profileData['name'] as String? ??
            profileData['username'] as String? ??
            profileData['displayName'] as String?;
        if (name != null && name.isNotEmpty) {
          setState(() {
            _displayName = name;
          });
          return;
        }
      }

      // Fallback to local storage if API fails
      final userData = await AuthService.getUserData();
      final name = userData['name'] ?? userData['username'];
      if (!mounted || name == null || name.isEmpty) return;
      setState(() {
        _displayName = name;
      });
    } catch (e) {
      debugPrint('Error loading user name: $e');
      // Ignore errors and keep the fallback name.
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        EventService.getEvents(),
        EventService.getUpcomingEvents(),
      ]);

      if (!mounted) return;
      setState(() {
        _popularEvents = results[0];
        _upcomingEvents = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        appBar: _topBar(context),
        floatingActionButton: _chatbotFab(context),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Error loading events',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadEvents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        // search bar
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.search),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: AppColors.muted),
                                SizedBox(width: 8),
                                Text('What would you like me to ask?',
                                    style: TextStyle(color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        const Text('Popular Events',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),

                        // horizontal cards
                        _popularEvents.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('No events available',
                                      style: TextStyle(color: AppColors.muted)),
                                ),
                              )
                            : SizedBox(
                                height: 252,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _popularEvents.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 14),
                                  itemBuilder: (context, i) {
                                    final e = _popularEvents[i];
                                    return _heroCard(context, e);
                                  },
                                ),
                              ),

                        const SizedBox(height: 16),
                        const Text('Upcoming events',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),

                        // vertical list
                        if (_upcomingEvents.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No upcoming events',
                                  style: TextStyle(color: AppColors.muted)),
                            ),
                          )
                        else
                          ..._upcomingEvents.map((e) => EventCard(
                                event: e,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.eventDetails,
                                    arguments: e.id),
                              )),
                      ],
                    ),
                  ),
      ),
    );
  }

  PreferredSizeWidget _topBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Remove back button
      titleSpacing: 16,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ]),
      actions: [
        Stack(
          children: [
            IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  _markNotificationsAsRead();
                  Navigator.of(context).pushNamed(NotificationFeedPage.route);
                }),
            if (_unreadNotificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _chatbotFab(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'chatbot-fab',
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chatbot),
      backgroundColor: Colors.white,
      elevation: 3,
      child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary),
    );
  }

  Widget _heroCard(BuildContext context, e) {
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.eventDetails, arguments: e.id),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 280,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // lower image height (was AspectRatio 16/9 ≈ 157.5px)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 132, // <= key: fits the 220 lane
                width: double.infinity,
                child: Image.network(
                  e.primaryImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 40),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 10, 12, 10), // slightly tighter
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(e.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted))),
                  ]),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3), // slimmer chip
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 128, 255),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${e.priceBaht}B/Person',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
