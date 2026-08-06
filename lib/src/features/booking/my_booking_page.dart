import 'package:flutter/material.dart';
import 'package:tripnest/src/app_router.dart';
import 'package:tripnest/src/core/services/booking_service.dart';
import 'package:tripnest/src/core/services/event_service.dart';
import 'package:tripnest/src/core/theme/app_colors.dart';
import 'package:tripnest/src/core/utils/app_log.dart';
import 'package:tripnest/src/core/utils/date_format.dart';
import 'package:tripnest/src/models/booking.dart';
import 'package:tripnest/src/models/event.dart';

class MyBookingPage extends StatefulWidget {
  const MyBookingPage({super.key});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> {
  bool showUpcoming = true;

  // Single loading state for both sections — we load everything at once.
  bool _isLoading = false;
  String? _errorMessage;

  List<_BookingEntry> _upcomingBookings = const [];
  List<_CompletedEntry> _completedEntries = const [];

  @override
  void initState() {
    super.initState();
    _loadAllBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking'),
        leading: BackButton(
          // Prefer a plain pop: rebuilding the whole shell threw away the
          // navigation stack on every back press.
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              navigator.pushNamedAndRemoveUntil(
                  AppRoutes.appShell, (_) => false,
                  arguments: 0);
            }
          },
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
              : _buildCompletedSection(context)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

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
      return [_errorCard(_errorMessage!, _loadAllBookings)];
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

  List<Widget> _buildCompletedSection(BuildContext context) {
    if (_isLoading) {
      return const [
        SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [_errorCard(_errorMessage!, _loadAllBookings)];
    }

    if (_completedEntries.isEmpty) {
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

    return List.generate(
      _completedEntries.length,
      (i) {
        final entry = _completedEntries[i];
        return _CompletedBookingTile(
          event: entry.event,
          trailing: TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.review,
                arguments: entry.event.id),
            child: const Text('Write a review'),
          ),
          onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetails,
              arguments: entry.event.id),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Data loading — single source of truth
  // ---------------------------------------------------------------------------

  /// Loads all bookings once, fetches their event details, then splits them
  /// into upcoming vs completed based on the event date vs today's date.
  Future<void> _loadAllBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // midnight today

      final bookings = await BookingService.getMyBookings();

      final upcoming = <_BookingEntry>[];
      final completed = <_CompletedEntry>[];

      // One request per booking, run in parallel: serialised, a 10-booking
      // list took ten round trips end to end.
      final events = await Future.wait(bookings.map((booking) async {
        try {
          return await EventService.getEventById(booking.eventId);
        } catch (e) {
          AppLog.e('Failed to load event ${booking.eventId}', e);
          return null;
        }
      }));

      for (var i = 0; i < bookings.length; i++) {
        final booking = bookings[i];
        final Event? event = events[i];

        // Determine bucket using the event date (client-side, real-time).
        // If the event detail couldn't be loaded, fall back to the server flag.
        final bool isUpcoming = event != null
            ? !event.date.isBefore(today) // event date >= today → upcoming
            : booking.isUpcoming;

        if (isUpcoming) {
          upcoming.add(_BookingEntry(booking: booking, event: event));
        } else if (event != null) {
          // Only add to completed when we have the full event object.
          completed.add(_CompletedEntry(booking: booking, event: event));
        }
      }

      // Upcoming: soonest event first (ascending).
      upcoming.sort((a, b) {
        final dateA = a.event?.date ?? a.booking.createdAt;
        final dateB = b.event?.date ?? b.booking.createdAt;
        return dateA.compareTo(dateB);
      });

      // Completed: most recently booked first (descending by booking date).
      completed.sort(
          (a, b) => b.booking.createdAt.compareTo(a.booking.createdAt));

      if (!mounted) return;
      setState(() {
        _upcomingBookings = upcoming;
        _completedEntries = completed;
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _errorCard(String message, VoidCallback onRetry) {
    return Container(
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
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
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

// =============================================================================
// Internal data models
// =============================================================================

class _BookingEntry {
  final Booking booking;
  final Event? event;
  const _BookingEntry({required this.booking, required this.event});
}

class _CompletedEntry {
  final Booking booking;
  final Event event;
  const _CompletedEntry({required this.booking, required this.event});
}

// =============================================================================
// Tile widgets
// =============================================================================

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

  @override
  Widget build(BuildContext context) {
    final DateTime date = event?.date ?? booking.createdAt;
    final day = date.day.toString().padLeft(2, '0');
    final mon = AppDate.monthShort(date.month);
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
                                fontSize: 11,
                                color: AppColors.textSecondary)),
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
                        errorBuilder: (_, __, ___) =>
                            const _ImagePlaceholder(),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
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
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
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

class _CompletedBookingTile extends StatelessWidget {
  const _CompletedBookingTile(
      {required this.event, this.trailing, this.onTap});

  static const double _minTileHeight = 118;
  final Event event;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = event.date;
    final day = d.day.toString().padLeft(2, '0');
    final mon = AppDate.monthShort(d.month);

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
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(mon,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
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
                      event.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _ImagePlaceholder(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
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