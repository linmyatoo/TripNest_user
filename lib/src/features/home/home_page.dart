import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/app_router.dart';

import '../../core/services/air_quality_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/event_service.dart';
import '../../core/services/review_service.dart';
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
  Map<String, double> _eventRatings = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _displayName = 'Traveler';
  int _unreadNotificationCount = 0;
  AirQualityData? _aqiData;
  bool _isLoadingAqi = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadEvents();
    _loadUnreadCount();
    _loadAqiData();
  }

  Future<void> _loadAqiData() async {
    if (_isLoadingAqi) return;
    setState(() => _isLoadingAqi = true);
    try {
      // First try to get cached data for instant display
      final cached = await AirQualityService.getCachedAqi();
      if (cached != null && mounted) {
        setState(() => _aqiData = cached);
      }
      // Then fetch fresh data
      final fresh = await AirQualityService.getAirQuality();
      if (fresh != null && mounted) {
        setState(() => _aqiData = fresh);
      }
    } catch (e) {
      debugPrint('Error loading AQI: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAqi = false);
    }
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
      // First load all events
      final results = await Future.wait([
        EventService.getEvents(),
        EventService.getUpcomingEvents(),
      ]);

      final allEvents = results[0];
      final upcomingEvents = results[1];

      // Only load ratings if logged in
      final isLoggedIn = await AuthService.isLoggedIn();
      Map<String, double> ratings = {};
      List<Event> popularEvents = allEvents;
      if (isLoggedIn) {
        final uniqueIds =
            [...allEvents, ...upcomingEvents].map((e) => e.id).toSet();
        await Future.wait(
          uniqueIds.map((eventId) async {
            try {
              final rating = await ReviewService.getEventAverageRating(eventId);
              if (rating != null) {
                ratings[eventId] = rating;
              }
            } catch (e) {
              debugPrint('Error loading rating for event $eventId: $e');
            }
          }),
        );
        // Filter popular events: only events with rating > 3
        popularEvents = allEvents.where((e) {
          final rating = ratings[e.id];
          return rating != null && rating > 3;
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _popularEvents = popularEvents;
        _upcomingEvents = upcomingEvents;
        _eventRatings = ratings;
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
                                Text('Search your events',
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
                          ..._upcomingEvents.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: EventCard(
                                event: e,
                                averageRating: _eventRatings[e.id],
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.eventDetails,
                                    arguments: e.id),
                              ),
                            ),
                          ),
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
        // AQI Widget
        if (_aqiData != null)
          GestureDetector(
            onTap: () => _showAqiDetails(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Color(_aqiData!.colorValue).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(_aqiData!.colorValue).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AQI',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(_aqiData!.colorValue),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_aqiData!.aqi}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(_aqiData!.colorValue),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_isLoadingAqi)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
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

  void _showAqiDetails(BuildContext context) {
    if (_aqiData == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AqiDetailsSheet(aqiData: _aqiData!),
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
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF60A5FA), // light blue
                            Color(0xFF3B82F6), // medium blue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text('${e.priceBaht}฿ /Person',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
                          )),
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

/// Bottom sheet showing detailed AQI information
class _AqiDetailsSheet extends StatelessWidget {
  final AirQualityData aqiData;

  const _AqiDetailsSheet({required this.aqiData});

  @override
  Widget build(BuildContext context) {
    final aqiColor = Color(aqiData.colorValue);
    final bgColor = Color(aqiData.backgroundColorValue);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: aqiColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.air,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Air Quality Index',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          aqiData.cityName,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: aqiColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: aqiColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '${aqiData.aqi}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: aqiColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: aqiColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      aqiData.level,
                      style: TextStyle(
                        color: aqiColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  aqiData.healthRecommendation,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Pollutant details
          Row(
            children: [
              _buildPollutantCard(
                  'PM2.5', aqiData.pm25.toStringAsFixed(1), 'μg/m³', aqiColor),
              const SizedBox(width: 12),
              _buildPollutantCard(
                  'PM10', aqiData.pm10.toStringAsFixed(1), 'μg/m³', aqiColor),
              const SizedBox(width: 12),
              _buildPollutantCard('Temp',
                  '${aqiData.temperature.toStringAsFixed(0)}°C', '', aqiColor),
            ],
          ),
          const SizedBox(height: 16),
          // Last updated
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: ${_formatTime(aqiData.updatedAt)}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPollutantCard(
      String label, String value, String unit, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
