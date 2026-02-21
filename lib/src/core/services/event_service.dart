import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/event.dart';

/// Pairs an [Event] with its live ticket availability data so callers can
/// compute booking percentages without making a second network call.
class EventAvailability {
  final Event event;

  /// Number of confirmed bookings (from the availability API).
  final int bookedTickets;

  /// Total capacity of the event.
  final int capacity;

  /// Whether every ticket has been sold.
  final bool isFullyBooked;

  const EventAvailability({
    required this.event,
    required this.bookedTickets,
    required this.capacity,
    required this.isFullyBooked,
  });

  /// Percentage of tickets that have been booked (0–100).
  double get bookedPercentage =>
      capacity > 0 ? (bookedTickets / capacity) * 100 : 0;
}

class EventService {
  static const String baseUrl = 'https://naylinhtet.me/api';

  /// Fetch all events
  static Future<List<Event>> getEvents() async {
    try {
      final url = Uri.parse('$baseUrl/events');

      print('Fetching events from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print('Error fetching events: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Fetch upcoming events (future dates, sorted ascending by date).
  static Future<List<Event>> getUpcomingEvents() async {
    try {
      final url = Uri.parse('$baseUrl/events/upcoming');

      print('Fetching upcoming events from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load upcoming events');
      }
    } catch (e) {
      print('Error fetching upcoming events: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Fetch events with ticket availability data.
  ///
  /// Returns a flat list of [EventAvailability] objects that contain both the
  /// [Event] model and the raw booking numbers (`bookedTickets`, `capacity`).
  /// Fully-booked events are included and flagged via [EventAvailability.isFullyBooked].
  ///
  /// GET /api/events/tickets/availability
  static Future<List<EventAvailability>> getEventsByTicketAvailability() async {
    try {
      final url = Uri.parse('$baseUrl/events/tickets/availability');

      print('Fetching ticket availability from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Ticket availability status: ${response.statusCode}');
      print('Ticket availability body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        final sortedRaw =
            (body['eventsSortedByAvailability'] as List<dynamic>?) ?? [];
        final fullyBookedRaw =
            (body['fullyBookedEvents'] as List<dynamic>?) ?? [];

        EventAvailability _fromSorted(dynamic raw) {
          final map = raw as Map<String, dynamic>;
          final capacity = (map['capacity'] as num?)?.toInt() ?? 0;
          final booked = (map['bookedTickets'] as num?)?.toInt() ?? 0;
          return EventAvailability(
            event: Event.fromJson(map),
            bookedTickets: booked,
            capacity: capacity,
            isFullyBooked: false,
          );
        }

        EventAvailability _fromFullyBooked(dynamic raw) {
          final map = raw as Map<String, dynamic>;
          final capacity = (map['capacity'] as num?)?.toInt() ?? 0;
          return EventAvailability(
            event: Event.fromJson(map),
            bookedTickets: capacity, // fully booked → booked == capacity
            capacity: capacity,
            isFullyBooked: true,
          );
        }

        return [
          ...sortedRaw.map(_fromSorted),
          ...fullyBookedRaw.map(_fromFullyBooked),
        ];
      } else {
        throw Exception('Failed to load ticket availability');
      }
    } catch (e) {
      print('Error fetching ticket availability: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Fetch a single event by ID
  static Future<Event> getEventById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/events/$id');

      print('Fetching event from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else {
        throw Exception('Failed to load event');
      }
    } catch (e) {
      print('Error fetching event: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Search events by location, keyword, or mood
  static Future<List<Event>> searchEvents({
    String? location,
    String? keyword,
    String? mood,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (mood != null && mood.isNotEmpty) {
        queryParams['mood'] = mood;
      }

      final url = Uri.parse('$baseUrl/events/search')
          .replace(queryParameters: queryParams);

      print('Searching events from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search events');
      }
    } catch (e) {
      print('Error searching events: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }
}