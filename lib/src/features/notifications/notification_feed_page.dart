import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';

class NotificationFeedPage extends StatefulWidget {
  static const route = '/notifications-feed';
  const NotificationFeedPage({super.key});

  @override
  State<NotificationFeedPage> createState() => _NotificationFeedPageState();
}

class _NotificationFeedPageState extends State<NotificationFeedPage> {
  List<_NotificationData> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to view your notifications.';
        });
        return;
      }

      final bookings = await BookingService.getMyBookings();
      final notifications = bookings
          .map((booking) => _NotificationData(
                id: booking.id,
                title: 'Booking Confirmation',
                descriptionPrefix: 'Your booking has been confirmed! ',
                ticketCountLabel: '${booking.ticketCount} tickets',
                amountLabel: ' for ฿${booking.totalPrice.toStringAsFixed(2)}. ',
                bookingIdLabel: 'Booking ID: ${booking.id}. ',
                paymentStatusLabel: booking.status,
                timeLabel: _formatRelativeTime(booking.createdAt),
                isRead: false,
              ))
          .toList();

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('Not authenticated')
          ? 'Session expired. Please log in again to refresh your notifications.'
          : e.toString();

      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    }
  }

  String _formatRelativeTime(DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final weeks = (difference.inDays / 7).floor();
    if (weeks < 5) {
      return '${weeks}w ago';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year;

    return '$month $day, $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notification'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Error loading notifications'),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No notifications yet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemBuilder: (context, index) => _SimpleNotificationCard(
          notification: _notifications[index],
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _notifications.length,
      ),
    );
  }
}

class _NotificationData {
  final String id;
  final String title;
  final String descriptionPrefix;
  final String ticketCountLabel;
  final String amountLabel;
  final String bookingIdLabel;
  final String paymentStatusLabel;
  final String timeLabel;
  bool isRead;

  _NotificationData({
    required this.id,
    required this.title,
    required this.descriptionPrefix,
    required this.ticketCountLabel,
    required this.amountLabel,
    required this.bookingIdLabel,
    required this.paymentStatusLabel,
    required this.timeLabel,
    this.isRead = false,
  });
}

class _SimpleNotificationCard extends StatelessWidget {
  final _NotificationData notification;

  const _SimpleNotificationCard({
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: textTheme.titleMedium
                        ?.copyWith(color: const Color(0xFF2563EB)),
                  ),
                ),
                Text(notification.timeLabel,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: textTheme.bodyMedium,
                children: [
                  TextSpan(text: notification.descriptionPrefix),
                  TextSpan(
                    text: notification.ticketCountLabel,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextSpan(text: notification.amountLabel),
                  TextSpan(text: notification.bookingIdLabel),
                  const TextSpan(text: 'Booking status: '),
                  TextSpan(
                    text: notification.paymentStatusLabel,
                    style: const TextStyle(color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
