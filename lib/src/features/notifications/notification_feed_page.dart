import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/notification_service.dart';

class NotificationFeedPage extends StatefulWidget {
  static const route = '/notifications-feed';
  const NotificationFeedPage({super.key});

  @override
  State<NotificationFeedPage> createState() => _NotificationFeedPageState();
}

class _NotificationFeedPageState extends State<NotificationFeedPage> {
  List<_UnifiedNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<_UnifiedNotification> allNotifications = [];

      // Load PM2.5/AQI notifications from NotificationService
      final appNotifications = await NotificationService.getNotifications();
      for (final n in appNotifications) {
        allNotifications.add(_UnifiedNotification(
          id: n.id,
          type: _NotificationType.aqi,
          title: n.title,
          body: n.body,
          createdAt: n.createdAt,
          isRead: n.isRead,
        ));
      }

      // Load booking notifications if logged in
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final bookings = await BookingService.getMyBookings();
        for (final booking in bookings) {
          allNotifications.add(_UnifiedNotification(
            id: booking.id,
            type: _NotificationType.booking,
            title: 'Booking Confirmation',
            body: '',
            createdAt: booking.createdAt,
            isRead: false,
            ticketCount: booking.ticketCount,
            totalPrice: booking.totalPrice,
            bookingStatus: booking.status,
          ));
        }
      }

      // Sort by date, newest first
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await NotificationService.markAllAsRead();

      if (!mounted) return;
      setState(() {
        _notifications = allNotifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<_UnifiedNotification>> _groupByDate() {
    final Map<String, List<_UnifiedNotification>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final n in _notifications) {
      final date =
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else {
        label = '${date.day}/${date.month}/${date.year}';
      }
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(n);
    }
    return grouped;
  }

  String _formatRelativeTime(DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.isNegative || difference.inMinutes < 1) {
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
    return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notification'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: _buildGroupedList(),
                  ),
                ),
    );
  }

  List<Widget> _buildGroupedList() {
    final grouped = _groupByDate();
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      widgets.add(_Label(entry.key));
      widgets.add(const SizedBox(height: 8));
      for (final notification in entry.value) {
        if (notification.type == _NotificationType.booking) {
          widgets.add(_BookingNotificationCard(
            notification: notification,
            timeLabel: _formatRelativeTime(notification.createdAt),
          ));
        } else {
          widgets.add(_SimpleNotificationCard(
            title: notification.title,
            body: notification.body,
            time: _formatRelativeTime(notification.createdAt),
            isRead: notification.isRead,
          ));
        }
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }
}

enum _NotificationType { booking, aqi }

class _UnifiedNotification {
  final String id;
  final _NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final int? ticketCount;
  final double? totalPrice;
  final String? bookingStatus;

  _UnifiedNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.ticketCount,
    this.totalPrice,
    this.bookingStatus,
  });
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFF6B7280)));
  }
}

/// Booking notification card with blue styling
class _BookingNotificationCard extends StatelessWidget {
  final _UnifiedNotification notification;
  final String timeLabel;

  const _BookingNotificationCard({
    required this.notification,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EC)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
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
                  Text(timeLabel, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Your booking has been confirmed! '),
                    TextSpan(
                      text: '${notification.ticketCount} tickets',
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                        text:
                            ' for ฿${notification.totalPrice?.toStringAsFixed(2)}. '),
                    TextSpan(text: 'Booking ID: ${notification.id}. '),
                    const TextSpan(text: 'Booking status: '),
                    TextSpan(
                      text: notification.bookingStatus ?? 'Confirmed',
                      style: const TextStyle(color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PM2.5/AQI notification card - colored by safety level
class _SimpleNotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isRead;

  const _SimpleNotificationCard({
    required this.title,
    required this.body,
    required this.time,
    this.isRead = true,
  });

  /// Parse AQI value from body text (format: "AQI: 125 (...")
  int? _parseAqi() {
    final match = RegExp(r'AQI:\s*(\d+)').firstMatch(body);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Get title color based on AQI level
  Color _getTitleColor(int? aqi) {
    if (aqi == null) return const Color(0xFF16A34A); // Default green
    if (aqi <= 50) return const Color(0xFF16A34A); // Green - Good
    if (aqi <= 100) return const Color(0xFFCA8A04); // Yellow - Moderate
    return const Color(0xFFDC2626); // Red - Unhealthy
  }

  /// Get background color based on AQI level
  Color _getBackgroundColor(int? aqi, bool isRead) {
    if (isRead) return Colors.white;
    if (aqi == null) return const Color(0xFFDCFCE7); // Default light green
    if (aqi <= 50) return const Color(0xFFDCFCE7); // Light green
    if (aqi <= 100) return const Color(0xFFFEF9C3); // Light yellow
    return const Color(0xFFFEE2E2); // Light red
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final aqi = _parseAqi();
    final titleColor = _getTitleColor(aqi);
    final bgColor = _getBackgroundColor(aqi, isRead);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EC)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
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
                      title,
                      style: textTheme.titleMedium?.copyWith(color: titleColor),
                    ),
                  ),
                  Text(time, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
