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

    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      shortLocation: _extractShortLocation(json['location'] ?? ''),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      priceBaht: (json['price'] ?? 0).toInt(),
      imageUrl: resolvedImageUrl,
      gallery: combinedGallery,
      capacity: json['capacity'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
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
