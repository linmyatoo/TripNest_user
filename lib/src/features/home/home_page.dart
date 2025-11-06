import 'package:flutter/material.dart';
import 'package:tripnest/src/app_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock_events.dart';
import '../../widgets/event_card.dart';
import '../notifications/notification_feed_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _topBar(context),
      floatingActionButton: _chatbotFab(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // search bar
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.search),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD1D5DB)),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),

          // horizontal cards like your hero cards
          SizedBox(
            height: 252,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockEvents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final e = mockEvents[i];
                return _heroCard(context, e);
              },
            ),
          ),

          const SizedBox(height: 16),
          const Text('Upcoming events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          // vertical list matching your “Upcoming events”
          ...mockEvents.map((e) => EventCard(
                event: e,
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.eventDetails,
                    arguments: e),
              )),
        ],
      ),
    );
  }

  PreferredSizeWidget _topBar(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Harry',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 2),
        Row(children: [
          Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
          SizedBox(width: 4),
          Text('Chiang Rai , Thailand',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ]),
      actions: [
        IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(NotificationFeedPage.route)),
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
          Navigator.pushNamed(context, AppRoutes.eventDetails, arguments: e),
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
                  e.imageUrl,
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
