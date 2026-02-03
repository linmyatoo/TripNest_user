class Event {
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
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      shortLocation: _extractShortLocation(json['location'] ?? ''),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      priceBaht: (json['price'] ?? 0).toInt(),
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/400x300',
      gallery:
          json['gallery'] != null ? List<String>.from(json['gallery']) : [],
      capacity: json['capacity'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static String _extractShortLocation(String fullLocation) {
    // Extract city from location string like "Central Park, NYC" -> "NYC"
    final parts = fullLocation.split(',');
    return parts.length > 1 ? parts.last.trim() : fullLocation;
  }
}
