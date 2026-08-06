import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/services/event_service.dart';
import '../../core/services/favorite_service.dart';
import '../../core/services/review_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/event.dart';
import '../../widgets/event_card.dart';
import '../../core/utils/app_log.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Event> _favoriteEvents = [];
  final Map<String, double> _eventRatings = {};
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

      // Fetch in parallel: one round trip per favorite, serialised, made the
      // list take as long as the slowest N requests summed together.
      final results = await Future.wait(
        favoriteIds.map((id) async {
          try {
            return await EventService.getEventById(id);
          } catch (e) {
            AppLog.e('Failed to load favorited event', e);
            return null;
          }
        }),
      );
      final events = results.whereType<Event>().toList();

      if (mounted) {
        setState(() {
          _favoriteEvents = events;
          _isLoading = false;
        });
        
        // Load ratings in background
        _loadEventRatings();
      }
    } catch (e) {
      AppLog.e('Failed to load favorites', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fetches every rating concurrently and applies them in a single setState,
  /// instead of one rebuild per event.
  Future<void> _loadEventRatings() async {
    final events = List<Event>.from(_favoriteEvents);
    final ratings = <String, double>{};

    await Future.wait(events.map((event) async {
      try {
        final rating = await ReviewService.getEventAverageRating(event.id);
        if (rating != null) ratings[event.id] = rating;
      } catch (e) {
        AppLog.e('Failed to load rating for event ${event.id}', e);
      }
    }));

    if (!mounted || ratings.isEmpty) return;
    setState(() => _eventRatings.addAll(ratings));
  }

  /// Removes the favorite, keeping the row in place if the removal fails —
  /// a dismissed row whose item is still in the list throws.
  Future<bool> _removeFavorite(String eventId) async {
    try {
      await FavoriteService.removeFavorite(eventId);
      if (!mounted) return true;
      setState(() {
        _favoriteEvents.removeWhere((e) => e.id == eventId);
        _eventRatings.remove(eventId);
      });
      return true;
    } catch (e) {
      AppLog.e('Failed to remove favorite', e);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove this favorite. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
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
                        confirmDismiss: (_) => _removeFavorite(event.id),
                        child: EventCard(
                          event: event,
                          averageRating: _eventRatings[event.id],
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.eventDetails,
                              arguments: event.id,
                            );
                            // Reload when returning: the user may have
                            // unfavorited from the detail page.
                            if (mounted) _loadFavorites();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
