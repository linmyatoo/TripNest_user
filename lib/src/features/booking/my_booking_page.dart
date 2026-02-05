import 'package:flutter/material.dart';
import 'package:tripnest/src/app_router.dart';
import 'package:tripnest/src/core/services/booking_service.dart';
import 'package:tripnest/src/core/services/event_service.dart';
import 'package:tripnest/src/core/theme/app_colors.dart';
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
  bool _completedLoading = false;
  String? _errorMessage;
  String? _completedError;
  List<_BookingEntry> _upcomingBookings = const [];
  List<Event> _completedEvents = const [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingBookings();
    _loadCompletedEvents();
  }

  @override
  Widget build(BuildContext context) {
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
              : _buildCompletedSection()),
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
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
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

  List<Widget> _buildCompletedSection() {
    if (_completedLoading) {
      return const [
        SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_completedError != null) {
      return [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 42),
              const SizedBox(height: 8),
              const Text('Unable to load completed events',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                _completedError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadCompletedEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ],
          ),
        )
      ];
    }

    if (_completedEvents.isEmpty) {
      return const [
        SizedBox(
          height: 160,
          child: Center(
            child: Text('No completed events yet.',
                style: TextStyle(color: AppColors.muted)),
          ),
        ),
      ];
    }

    final completed = _completedEvents;
    return List.generate(
      completed.length,
      (i) {
        final e = completed[i];
        return _CompletedBookingTile(
          event: e,
          trailing: TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.review, arguments: e.id),
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

  Future<void> _loadCompletedEvents() async {
    setState(() {
      _completedLoading = true;
      _completedError = null;
    });

    try {
      // Get user's bookings and filter for completed ones
      final bookings = await BookingService.getMyBookings();
      final completedBookings = bookings.where((b) => !b.isUpcoming).toList();

      // Fetch event details for each completed booking
      final completedEvents = <Event>[];
      for (final booking in completedBookings) {
        try {
          final event = await EventService.getEventById(booking.eventId);
          completedEvents.add(event);
        } catch (e) {
          debugPrint('Failed to load event ${booking.eventId}: $e');
        }
      }

      // Also add upcoming bookings for testing reviews
      final upcomingBookings = bookings.where((b) => b.isUpcoming).toList();
      for (final booking in upcomingBookings) {
        try {
          final event = await EventService.getEventById(booking.eventId);
          completedEvents.add(event);
        } catch (e) {
          debugPrint('Failed to load event ${booking.eventId}: $e');
        }
      }

      // Sort by date (most recent first)
      completedEvents.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _completedEvents = completedEvents;
        _completedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _completedLoading = false;
        _completedError = e.toString().replaceFirst('Exception: ', '');
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
  static const double _minTileHeight = 118;
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

    final heroImage = event.primaryImage;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minTileHeight),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(mon,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 92,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      heroImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _ImagePlaceholder();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const _ImagePlaceholder(isLoading: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(event.shortLocation,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        if (trailing != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: trailing!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
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

  static const double _minTileHeight = 118;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minTileHeight),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(mon,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 92,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: (() {
                      final heroImage = event?.primaryImage;
                      if (heroImage == null || heroImage.isEmpty) {
                        return const _ImagePlaceholder();
                      }
                      return Image.network(
                        heroImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const _ImagePlaceholder();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const _ImagePlaceholder(isLoading: true);
                        },
                      );
                    })(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event?.title ?? fallbackTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event?.shortLocation ??
                              'Event ID: ${booking.eventId}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                booking.status,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${booking.ticketCount} ticket(s)',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
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
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey[isLoading ? 200 : 300],
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image_not_supported,
                color: Colors.grey, size: 28),
      ),
    );
  }
}
