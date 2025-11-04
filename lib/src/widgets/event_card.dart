import 'package:flutter/material.dart';
import '../models/event.dart';
import '../core/theme/app_colors.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.width, // when used in horizontal lists, give a width (e.g., 300)
  });

  final Event event;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width, // if null, it will take max available width from parent
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Thumbnail (fixed size -> always has constraints)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              event.imageUrl,
              width: 92,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // Text/content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // don't demand infinite height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.shortLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // rating + price row
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Color(0xFFFFB300)),
                    const SizedBox(width: 4),
                    Text(
                      'N/A',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${event.priceBaht}B/Person',
                        // or: money(event.priceBaht) if you use a formatter
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}
