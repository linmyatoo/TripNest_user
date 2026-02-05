import 'package:flutter/material.dart';
import 'package:tripnest/src/app_router.dart';
import 'package:tripnest/src/core/services/event_service.dart';
import 'package:tripnest/src/core/services/review_service.dart';
import 'package:tripnest/src/core/widgets/primary_button.dart';
import 'package:tripnest/src/models/event.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.eventId});
  final String eventId;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double rating = 4;
  final textCtrl = TextEditingController();
  Event? _event;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = await EventService.getEventById(widget.eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: Builder(builder: (context) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Retry', onPressed: _loadEvent),
              ],
            ),
          );
        }

        if (event == null) {
          return const Center(child: Text('Event not found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    event.primaryImage,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 24),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),
                title: Text(event.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(event.shortLocation),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => rating = i + 1),
                  icon: Icon(i < rating ? Icons.star : Icons.star_border,
                      size: 28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Take rewards by giving review'),
            const SizedBox(height: 8),
            TextField(
              controller: textCtrl,
              minLines: 4,
              maxLines: 6,
              decoration:
                  const InputDecoration(hintText: 'Share your experience!'),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isSubmitting ? 'Submitting...' : 'Submit',
              onPressed: _isSubmitting ? null : _submitReview,
            ),
          ],
        );
      }),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      await ReviewService.submitReview(
        eventId: widget.eventId,
        rating: rating.toInt(),
        comment: textCtrl.text.trim().isNotEmpty ? textCtrl.text.trim() : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! You earned your reward.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to booking page
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.myBooking,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
