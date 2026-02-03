class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // BOOKING, REMINDER, PROMOTION, etc.
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata; // For additional data like bookingId

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'] ?? 'GENERAL',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays < 7 && difference.inDays > 0;
  }
}
