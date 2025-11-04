import 'package:flutter/material.dart';

class NotificationFeedPage extends StatelessWidget {
  static const route = '/notifications-feed';
  const NotificationFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Notification')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          _Label('Today'),
          SizedBox(height: 8),
          _SimpleNotificationCard(
            title: 'Booking Confirmation — Flower Festival',
            body:
                '''Chiang Mai Coffee Tasting Workshop on 15 Sep, 2:00 PM. Your booking code: TNX-CM4521. A confirmation email has been sent to you.''',
            time: '2m ago',
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFF6B7280)));
  }
}

/// iPhone-like card WITHOUT app name/logo — just Title, Time (right), Body.
class _SimpleNotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SimpleNotificationCard({
    required this.title,
    required this.body,
    required this.time,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE6E8EC)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + time (time on the right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: titleColor ?? const Color(0xFF111827),
                            ) ??
                            TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: titleColor ?? const Color(0xFF111827),
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time,
                        style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: text.bodyMedium
                          ?.copyWith(color: const Color(0xFF1F2937)) ??
                      const TextStyle(color: Color(0xFF1F2937)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
