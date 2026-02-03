import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/services/event_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadEvent();
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
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {})
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
                  color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: RichText(
                text: TextSpan(
                    style: const TextStyle(color: AppColors.textSecondary),
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
                arguments: {'event': event, 'personCount': _personCount},
              ),
            )),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // hero image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Image.network(
              event.imageUrl,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 260,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 60),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 260,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place_outlined,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(event.location,
                    style: const TextStyle(color: AppColors.muted)),
              ]),
              const SizedBox(height: 16),
              const Text('Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(event.description * 2), // doubled to mimic long text for now
              const SizedBox(height: 16),
              const Text('Reviews',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Reviews will appear here... See More...'),
              const SizedBox(height: 16),
              const Text('Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                      child: Image.network(
                        url,
                        width: 100,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 72,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 30),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            height: 72,
                            color: Colors.grey[200],
                            child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // map placeholder
              const Text('Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                  border: Border.all(color: AppColors.border.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.muted),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Number of Persons',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    _CounterButton(
                      icon: Icons.remove,
                      onTap: _personCount > 1
                          ? () => setState(() => _personCount -= 1)
                          : null,
                    ),
                    SizedBox(
                      width: 40,
                      child: Text('$_personCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    _CounterButton(
                      icon: Icons.add,
                      onTap: () => setState(() => _personCount += 1),
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
            color: Colors.white.withOpacity(onTap == null ? 0.4 : 1), size: 18),
      ),
    );
  }
}
