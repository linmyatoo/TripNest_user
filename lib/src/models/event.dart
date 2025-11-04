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
  });
}
