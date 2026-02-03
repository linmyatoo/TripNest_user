import 'package:flutter/material.dart';
import 'package:tripnest/src/app_router.dart';
import 'package:tripnest/src/core/services/booking_service.dart';
import 'package:tripnest/src/core/services/event_service.dart';
import 'package:tripnest/src/core/theme/app_colors.dart';
import 'package:tripnest/src/data/mock_events.dart';
import 'package:tripnest/src/models/booking.dart';
import 'package:tripnest/src/models/event.dart';

class MyBookingPage extends StatefulWidget {
  const MyBookingPage({super.key});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> {
  bool showUpcoming = true;
  bool _isLoading = false;
  String? _errorMessage;
  List<_BookingEntry> _upcomingBookings = const [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingBookings();
  }

  @override
  Widget build(BuildContext context) {
    final completed = mockEvents; // Completed tab still uses mock data for now

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking'),
        leading: BackButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.appShell, (_) => false,
              arguments: 0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              _pill(
                selected: showUpcoming,
                label: 'Upcoming',
                onTap: () => setState(() => showUpcoming = true),
              ),
              const SizedBox(width: 10),
              _pill(
                selected: !showUpcoming,
                label: 'Completed',
                onTap: () => setState(() => showUpcoming = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            showUpcoming ? 'Your Upcoming events' : 'Your completed events',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...(showUpcoming
              ? _buildUpcomingSection(context)
              : _buildCompletedSection(completed)),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingSection(BuildContext context) {
    if (_isLoading) {
      return const [
        SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 42),
              const SizedBox(height: 8),
              const Text('Unable to load bookings',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadUpcomingBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ],
          ),
        )
      ];
    }

    if (_upcomingBookings.isEmpty) {
      return const [
        SizedBox(
          height: 160,
          child: Center(
            child: Text('No upcoming bookings yet.',
                style: TextStyle(color: AppColors.muted)),
          ),
        ),
      ];
    }

    return _upcomingBookings
        .map((entry) => _UpcomingBookingTile(
              booking: entry.booking,
              event: entry.event,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.eventDetails,
                arguments: entry.booking.eventId,
              ),
              onDetailsTap: () => Navigator.pushNamed(
                context,
                AppRoutes.eventDetails,
                arguments: entry.booking.eventId,
              ),
            ))
        .toList();
  }

  List<Widget> _buildCompletedSection(List<Event> completed) {
    return List.generate(
      completed.length,
      (i) {
        final e = completed[i];
        return _CompletedBookingTile(
          event: e,
          trailing: i == (completed.length - 1)
              ? const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text('Rewarded',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                )
              : TextButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.review,
                      arguments: e.id),
                  child: const Text('Write a review'),
                ),
          onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetails,
              arguments: e.id),
        );
      },
    );
  }

  Future<void> _loadUpcomingBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookings = await BookingService.getMyBookings();
      final upcoming = bookings.where((b) => b.isUpcoming).toList();

      final entries = <_BookingEntry>[];
      for (final booking in upcoming) {
        Event? event;
        try {
          event = await EventService.getEventById(booking.eventId);
        } catch (e) {
          debugPrint('Failed to load event ${booking.eventId}: $e');
        }
        entries.add(_BookingEntry(booking: booking, event: event));
      }

      if (!mounted) return;
      setState(() {
        _upcomingBookings = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _pill(
      {required bool selected, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _CompletedBookingTile extends StatelessWidget {
  const _CompletedBookingTile({required this.event, this.trailing, this.onTap});
  final Event event;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = event.date;
    final day = d.day.toString().padLeft(2, '0');
    final mon = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][d.month - 1];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // date pill
          Container(
            width: 52,
            height: 92,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(day,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(mon,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(width: 12),
          // image + info
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              event.imageUrl,
              width: 88,
              height: 66,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 88,
                  height: 66,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 28),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 88,
                  height: 66,
                  color: Colors.grey[200],
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(event.shortLocation,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ]),
          ),
          if (trailing != null)
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing!,
              ),
            ),
        ]),
      ),
    );
  }
}

class _BookingEntry {
  final Booking booking;
  final Event? event;
  const _BookingEntry({required this.booking, required this.event});
}

class _UpcomingBookingTile extends StatelessWidget {
  const _UpcomingBookingTile({
    required this.booking,
    this.event,
    this.onTap,
    this.onDetailsTap,
  });

  final Booking booking;
  final Event? event;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsTap;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime date = event?.date ?? booking.createdAt;
    final day = date.day.toString().padLeft(2, '0');
    final mon = _months[date.month - 1];
    final fallbackTitle = booking.id.isNotEmpty
        ? 'Booking ${booking.id.substring(0, booking.id.length >= 6 ? 6 : booking.id.length)}'
        : 'Booking';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 92,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(mon,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: event?.imageUrl != null
                  ? Image.network(
                      event!.imageUrl,
                      width: 88,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _ImagePlaceholder();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _ImagePlaceholder(isLoading: true);
                      },
                    )
                  : const _ImagePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event?.title ?? fallbackTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event?.shortLocation ?? 'Event ID: ${booking.eventId}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          booking.status,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${booking.ticketCount} ticket(s)',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onDetailsTap,
                      child: const Text(
                        'See details....',
                        style: TextStyle(color: Color(0xFFFF6B6B)),
                      ),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.isLoading = false});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 66,
      color: Colors.grey[isLoading ? 200 : 300],
      child: isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.image_not_supported, color: Colors.grey, size: 28),
    );
  }
}
