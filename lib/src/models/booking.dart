class Booking {
  final String id;
  final String userId;
  final String eventId;
  final int ticketCount;
  final double totalPrice;
  final String status; // CONFIRMED, PENDING, CANCELLED, COMPLETED
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.ticketCount,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      eventId: json['eventId'] ?? '',
      ticketCount: _parseTicketCount(json),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: _parseDate(json['createdAt']) ??
          _parseDate(json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ??
          _parseDate(json['updated_at']) ??
          DateTime.now(),
    );
  }

  bool get isUpcoming => status == 'CONFIRMED' || status == 'PENDING';
  bool get isCompleted => status == 'COMPLETED';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    if (value is int) {
      // Treat large numbers as milliseconds since epoch, otherwise seconds.
      final isMillis =
          value.abs() > 100000000000; // roughly > year 5138 in seconds
      final timestamp = isMillis ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    }

    if (value is double) {
      final millis =
          (value > 100000000000) ? value.toInt() : (value * 1000).round();
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    return null;
  }

  static int _parseTicketCount(Map<String, dynamic> json) {
    final raw = json['ticketCount'] ?? json['ticketCounts'] ?? 0;
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }
}
