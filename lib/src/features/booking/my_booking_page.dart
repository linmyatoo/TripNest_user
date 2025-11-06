import 'package:flutter/material.dart';
import 'package:tripnest/src/app_router.dart';
import 'package:tripnest/src/core/theme/app_colors.dart';
import 'package:tripnest/src/data/mock_events.dart';
import 'package:tripnest/src/models/event.dart';

class MyBookingPage extends StatefulWidget {
  const MyBookingPage({super.key});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> {
  bool showUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final upcoming = mockEvents; // TODO: replace with real upcoming
    final completed = mockEvents; // TODO: replace with real completed

    return Scaffold(
      appBar: AppBar(title: const Text('My Booking')),
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
          ...List.generate(
            (showUpcoming ? upcoming : completed).length,
            (i) {
              final e = (showUpcoming ? upcoming : completed)[i];
              return _BookingTile(
                event: e,
                trailing: showUpcoming
                    ? TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.eventDetails,
                            arguments: e),
                        child: const Text(
                          'See details....',
                          style: TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      )
                    : (i == (completed.length - 1)
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
                          )),
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.eventDetails,
                    arguments: e),
              );
            },
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

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.event, this.trailing, this.onTap});
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
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}
