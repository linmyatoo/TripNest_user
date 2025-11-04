import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../core/theme/app_colors.dart';
import '../../app_router.dart';
import '../../core/widgets/primary_button.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {})],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(child: Container(
              height: 56,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: RichText(
                text: TextSpan(style: const TextStyle(color: AppColors.textSecondary), children: [
                  const TextSpan(text: 'Price  '),
                  TextSpan(text: '${event.priceBaht}Baht', style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                  const TextSpan(text: '  Person'),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Book Now',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.payment, arguments: event),
            )),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // hero image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Image.network(event.imageUrl, height: 260, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(event.location, style: const TextStyle(color: AppColors.muted)),
              ]),
              const SizedBox(height: 16),
              const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(event.description * 2), // doubled to mimic long text for now
              const SizedBox(height: 16),
              const Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Reviews will appear here... See More...'),
              const SizedBox(height: 16),
              const Text('Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: event.gallery.isEmpty ? 3 : event.gallery.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final url = (event.gallery.isEmpty)
                        ? event.imageUrl
                        : event.gallery[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(url, width: 100, height: 72, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // map placeholder
              const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(height: 140, color: const Color(0xFFEAF0F6),
                    alignment: Alignment.center, child: const Text('Map Placeholder')),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
