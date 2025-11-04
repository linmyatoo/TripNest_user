import 'package:flutter/material.dart';
import '../../data/mock_events.dart';
import '../../widgets/event_card.dart';
import '../../app_router.dart';

class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage({super.key, this.query});
  final Object? query; // you can define a proper model later

  @override
  Widget build(BuildContext context) {
    // currently returns all mock events; filter using `query` later
    final results = mockEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        leading: const BackButton(), // iOS swipe-back works via CupertinoPageRoute
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: results.map((e) => EventCard(
          event: e,
          onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetails, arguments: e),
        )).toList(),
      ),
    );
  }
}
