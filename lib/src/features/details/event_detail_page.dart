import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/services/event_service.dart';
import '../../core/services/favorite_service.dart';
import '../../core/services/review_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/event.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _event;
  bool _isLoading = true;
  String? _errorMessage;
  int _personCount = 1;
  bool _isFavorite = false;
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;
  Timer? _autoSlideTimer;
  List<Review> _reviews = [];
  double? _averageRating;

  // Ticket availability
  int? _availableTickets;
  int? _capacity;

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _checkFavoriteStatus();
    _loadReviews();
    _loadAverageRating();
    _loadAvailability();
  }

  /// Fetch ticket availability for this specific event from the availability API.
  Future<void> _loadAvailability() async {
    try {
      final all = await EventService.getEventsByTicketAvailability();
      final match = all.where((a) => a.event.id == widget.eventId);
      if (match.isNotEmpty && mounted) {
        final entry = match.first;
        setState(() {
          _availableTickets = entry.isFullyBooked
              ? 0
              : entry.capacity - entry.bookedTickets;
          _capacity = entry.capacity;
        });
      }
    } catch (e) {
      // Non-critical — silently ignore so the rest of the page still loads.
      debugPrint('Error loading availability: $e');
    }
  }

  Widget _photoCarousel(Event event) {
    final photos = event.photoGallery;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: PageView.builder(
              controller: _photoController,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemCount: photos.length,
              itemBuilder: (_, index) {
                final url = photos[index];
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 60),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child:
                          const Center(child: CircularProgressIndicator()),
                    );
                  },
                );
              },
            ),
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (index) {
                  final isActive = index == _currentPhotoIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: isActive ? 18 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoriteService.isFavorite(widget.eventId);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _loadReviews() async {
    final reviews = await ReviewService.getEventReviews(widget.eventId);
    if (mounted) setState(() => _reviews = reviews);
  }

  Future<void> _loadAverageRating() async {
    final rating =
        await ReviewService.getEventAverageRating(widget.eventId);
    if (mounted) setState(() => _averageRating = rating);
  }

  Future<void> _toggleFavorite() async {
    print('Toggling favorite for event ID: ${widget.eventId}');
    final newStatus =
        await FavoriteService.toggleFavorite(widget.eventId);
    print('New favorite status: $newStatus');

    final savedIds = await FavoriteService.getFavoriteIds();
    print('Current saved favorite IDs: $savedIds');

    if (mounted) {
      setState(() => _isFavorite = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              newStatus ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showFullImage(String url) async {
    final photos = _event?.photoGallery ?? [url];
    final initialIndex = photos.indexOf(url);
    final controller = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
    int currentIndex = controller.initialPage;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    onPageChanged: (index) {
                      setStateDialog(() => currentIndex = index);
                    },
                    itemCount: photos.length,
                    itemBuilder: (_, index) {
                      final photoUrl = photos[index];
                      return Center(
                        child: InteractiveViewer(
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                  size: 60);
                            },
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 24,
                    right: 24,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            List.generate(photos.length, (index) {
                          final isActive = index == currentIndex;
                          return AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4),
                            width: isActive ? 18 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_averageRating != null) ...[
          Row(
            children: [
              ...List.generate(5, (i) {
                final rating = _averageRating!;
                IconData icon;
                if (i < rating.floor()) {
                  icon = Icons.star;
                } else if (i < rating && rating - i >= 0.5) {
                  icon = Icons.star_half;
                } else {
                  icon = Icons.star_border;
                }
                return Icon(icon, color: Colors.amber, size: 20);
              }),
              const SizedBox(width: 8),
              Text(
                _averageRating!.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                ' (${_reviews.length} reviews)',
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_reviews.isEmpty)
          const Text('No reviews yet.',
              style: TextStyle(color: AppColors.muted))
        else
          ...(_reviews
              .take(3)
              .map((review) => _ReviewTile(review: review))),
      ],
    );
  }

  /// Availability badge shown above the event title.
  Widget _buildAvailabilityBadge() {
    if (_availableTickets == null) return const SizedBox.shrink();

    final isFullyBooked = _availableTickets == 0;
    final isLowStock =
        !isFullyBooked && _capacity != null && _availableTickets! <= 10;

    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (isFullyBooked) {
      bgColor = const Color(0xFFFFE4E4);
      textColor = const Color(0xFFDC2626);
      icon = Icons.event_busy_outlined;
      label = 'Fully Booked';
    } else if (isLowStock) {
      bgColor = const Color(0xFFFFF3CD);
      textColor = const Color(0xFFB45309);
      icon = Icons.local_fire_department_outlined;
      label = 'Only $_availableTickets seats left!';
    } else {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      icon = Icons.confirmation_num_outlined;
      label = '$_availableTickets seats available';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: textColor),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final event = await EventService.getEventById(widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
        _currentPhotoIndex = 0;
      });
      _restartAutoSlide();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _restartAutoSlide() {
    _autoSlideTimer?.cancel();
    final photos = _event?.photoGallery ?? [];
    if (photos.length <= 1) return;

    if (_photoController.hasClients) {
      _photoController.jumpToPage(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_photoController.hasClients) {
          _photoController.jumpToPage(0);
        }
      });
    }

    _autoSlideTimer =
        Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_photoController.hasClients) return;
      final photosLength = _event?.photoGallery.length ?? 0;
      if (photosLength <= 1) return;
      final next = (_currentPhotoIndex + 1) % photosLength;
      _photoController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading event',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Event not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadEvent,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null),
            onPressed: _toggleFavorite,
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
                child: Container(
              height: 56,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: RichText(
                text: TextSpan(
                    style: const TextStyle(
                        color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Price  '),
                      TextSpan(
                          text: '${event.priceBaht}Baht',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800)),
                      const TextSpan(text: '  Person'),
                    ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: PrimaryButton(
              label: 'Book Now',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.payment,
                arguments: {
                  'event': event,
                  'personCount': _personCount
                },
              ),
            )),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _photoCarousel(event),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Available seats badge (above title) ──────────────
                  _buildAvailabilityBadge(),

                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(event.location,
                        style:
                            const TextStyle(color: AppColors.muted)),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Details',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(event.description * 2),
                  const SizedBox(height: 16),
                  const Text('Reviews',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _buildReviewsSection(),
                  const SizedBox(height: 16),
                  const Text('Gallery',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: event.photoGallery.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final url = event.photoGallery[i];
                        return GestureDetector(
                          onTap: () => _showFullImage(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 100,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 72,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 30),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null)
                                  return child;
                                return Container(
                                  width: 100,
                                  height: 72,
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Location',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        height: 140,
                        color: const Color(0xFFEAF0F6),
                        alignment: Alignment.center,
                        child: const Text('Map Placeholder')),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.border
                              .withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: AppColors.muted),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Number of Persons',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        _CounterButton(
                          icon: Icons.remove,
                          onTap: _personCount > 1
                              ? () =>
                                  setState(() => _personCount -= 1)
                              : null,
                        ),
                        SizedBox(
                          width: 40,
                          child: Text('$_personCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                        ),
                        _CounterButton(
                          icon: Icons.add,
                          onTap: () =>
                              setState(() => _personCount += 1),
                        ),
                      ],
                    ),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.border : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: Colors.white
                .withValues(alpha: onTap == null ? 0.4 : 1),
            size: 18),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt;
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child:
                    Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(dateStr,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null &&
              review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style: const TextStyle(
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}