import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/services/event_service.dart';
import '../../core/services/review_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/event.dart';
import '../../widgets/event_card.dart';

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key, this.query});
  final Object? query;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Event> _results = [];
  Map<String, double> _eventRatings = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? location;
      String? keyword;
      String? mood;

      if (widget.query is Map<String, dynamic>) {
        final q = widget.query as Map<String, dynamic>;
        location = q['location'] as String?;
        keyword = q['keyword'] as String?;
        mood = q['mood'] as String?;
      }

      final events = await EventService.searchEvents(
        location: location,
        keyword: keyword,
        mood: mood,
      );

      if (!mounted) return;
      setState(() {
        _results = events;
        _isLoading = false;
      });

      // Load ratings in background
      _loadEventRatings();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEventRatings() async {
    for (final event in _results) {
      try {
        final rating = await ReviewService.getEventAverageRating(event.id);
        if (rating != null && mounted) {
          setState(() {
            _eventRatings[event.id] = rating;
          });
        }
      } catch (e) {
        debugPrint('Error loading rating for event ${event.id}: $e');
      }
    }
  }

  String _getSearchSummary() {
    if (widget.query is! Map<String, dynamic>) return 'Search Results';
    
    final q = widget.query as Map<String, dynamic>;
    final parts = <String>[];
    
    if (q['location'] != null && (q['location'] as String).isNotEmpty) {
      parts.add(q['location'] as String);
    }
    if (q['keyword'] != null && (q['keyword'] as String).isNotEmpty) {
      parts.add('"${q['keyword']}"');
    }
    if (q['mood'] != null && (q['mood'] as String).isNotEmpty) {
      parts.add(q['mood'] as String);
    }
    
    if (parts.isEmpty) return 'All Events';
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Error searching events',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _performSearch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No events found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search criteria',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _performSearch,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          // Search summary
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list, size: 18, color: AppColors.muted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getSearchSummary(),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_results.length} results',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Results
                          ..._results.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: EventCard(
                                  event: e,
                                  averageRating: _eventRatings[e.id],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.eventDetails,
                                    arguments: e.id,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
    );
  }
}
