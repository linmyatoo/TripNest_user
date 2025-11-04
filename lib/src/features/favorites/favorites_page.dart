import 'package:flutter/material.dart';
import '../../data/mock_events.dart';
import '../../widgets/event_card.dart';
import '../../app_router.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = mockEvents; // plug your wishlist here
    return Scaffold(
      appBar: AppBar(title: const Text('Your Favorite')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: favs.map((e) => EventCard(
          event: e,
          onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetails, arguments: e),
        )).toList(),
      ),
    );
  }
}
