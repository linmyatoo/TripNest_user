import '../core/utils/app_log.dart';

class Event {
  static const String _placeholderImage = 'https://via.placeholder.com/400x300';

  final String id;
  final String title;
  final String location;
  final DateTime date;
  final int priceBaht;
  final String imageUrl;
  final String shortLocation; // e.g., 'Chiang Rai'
  final String description;
  final List<String> gallery;
  final int? capacity;
  final int? availableTickets;
  final int? bookedTickets;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.shortLocation,
    required this.date,
    required this.priceBaht,
    required this.imageUrl,
    required this.description,
    required this.gallery,
    this.capacity,
    this.availableTickets,
    this.bookedTickets,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final eventPhotoUrls = _parseStringList(
      json['eventPhotoUrl'] ?? json['eventPhotoUrls'],
    );
    final galleryUrls = _parseStringList(json['gallery']);
    final imageObjects = _parseImageObjectList(json['images']);
    final primaryCombined = _mergeUniqueLists(eventPhotoUrls, galleryUrls);
    final combinedGallery = _mergeUniqueLists(primaryCombined, imageObjects);

    final resolvedImageUrl = _resolvePrimaryImage(
      explicitImage: json['imageUrl'],
      gallery: combinedGallery,
    );

    final location = json['location']?.toString() ?? '';

    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: location,
      shortLocation: _extractShortLocation(location),
      date: _parseDate(json['date']) ?? DateTime.now(),
      priceBaht: _parseInt(json['price']) ?? 0,
      imageUrl: resolvedImageUrl,
      gallery: combinedGallery,
      capacity: _parseInt(json['capacity']),
      availableTickets: _parseInt(json['availableTickets']),
      bookedTickets: _parseInt(json['bookedTickets']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  /// Parse a list of events, dropping records the server sent malformed.
  ///
  /// A single bad row used to throw out of [Event.fromJson] and take the whole
  /// response with it — 29 good events would vanish behind "Network error"
  /// because of one empty `date`.
  static List<Event> listFromJson(Iterable<dynamic> raw) {
    final events = <Event>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      try {
        events.add(Event.fromJson(item));
      } catch (e) {
        AppLog.e('Skipping malformed event record', e);
      }
    }
    return events;
  }

  /// Tolerates ints, numeric strings, and nulls. Never throws.
  static int? _parseInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Tolerates ISO strings, epoch millis, and junk like `""`. Never throws.
  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }

  static String _resolvePrimaryImage({
    String? explicitImage,
    required List<String> gallery,
  }) {
    final trimmed = explicitImage?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    if (gallery.isNotEmpty) {
      return gallery.first;
    }
    return _placeholderImage;
  }

  static String _extractShortLocation(String fullLocation) {
    // Extract city from location string like "Central Park, NYC" -> "NYC"
    final parts = fullLocation.split(',');
    return parts.length > 1 ? parts.last.trim() : fullLocation;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item is String ? item.trim() : '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    return [];
  }

  static List<String> _parseImageObjectList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((item) => item is Map<String, dynamic>
            ? (item['imageUrl'] ?? item['url'] ?? '').toString().trim()
            : '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static List<String> _mergeUniqueLists(
      List<String> primary, List<String> secondary) {
    if (primary.isEmpty && secondary.isEmpty) return [];
    final seen = <String>{};
    final merged = <String>[];
    for (final url in [...primary, ...secondary]) {
      final value = url.trim();
      if (value.isEmpty) continue;
      if (seen.add(value)) {
        merged.add(value);
      }
    }
    return merged;
  }

  List<String> get photoGallery {
    if (gallery.isNotEmpty) return gallery;
    return [imageUrl.isNotEmpty ? imageUrl : _placeholderImage];
  }

  String get primaryImage => photoGallery.first;
}
