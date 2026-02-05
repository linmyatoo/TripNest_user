import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/services/event_service.dart';
import '../../core/services/favorite_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/event.dart';
import '../../widgets/event_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Event> _favoriteEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final favoriteIds = await FavoriteService.getFavoriteIds();
      print('Loaded favorite IDs: $favoriteIds'); // Debug log

      final List<Event> events = [];

      // Fetch each favorited event
      for (final id in favoriteIds) {
        try {
          print('Fetching event with ID: $id'); // Debug log
          final event = await EventService.getEventById(id);
          events.add(event);
          print('Successfully loaded event: ${event.title}'); // Debug log
        } catch (e) {
          print('Failed to load event $id: $e'); // Debug log
          // Skip events that can't be loaded
        }
      }

      if (mounted) {
        setState(() {
          _favoriteEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(String eventId) async {
    await FavoriteService.removeFavorite(eventId);
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Favorite')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No favorites yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the heart icon on events\nto add them to your favorites',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _favoriteEvents.length,
                    itemBuilder: (context, index) {
                      final event = _favoriteEvents[index];
                      return Dismissible(
                        key: Key(event.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeFavorite(event.id),
                        child: EventCard(
                          event: event,
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.eventDetails,
                              arguments: event.id,
                            );
                            // Reload favorites when returning (in case user unfavorited)
                            _loadFavorites();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
