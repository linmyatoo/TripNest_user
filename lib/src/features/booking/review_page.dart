import 'package:flutter/material.dart';
import 'package:tripnest/src/core/widgets/primary_button.dart';
import 'package:tripnest/src/data/mock_events.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.eventId});
  final String eventId;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double rating = 4;
  final textCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final event = mockEvents.firstWhere((e) => e.id == widget.eventId);
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // header tile
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  event.imageUrl,
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
          // stars
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => rating = i + 1),
                icon:
                    Icon(i < rating ? Icons.star : Icons.star_border, size: 28),
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
            label: 'Submit',
            onPressed: () {
              // TODO: submit review
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
