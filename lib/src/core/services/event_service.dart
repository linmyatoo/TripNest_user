import 'dart:convert';


import '../../models/event.dart';
import '../utils/app_log.dart';
import 'session.dart';
import 'http_client.dart';
import '../config/api_endpoints.dart';

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
  static const String baseUrl = ApiEndpoints.baseUrl;

  /// Fetch all events
  static Future<List<Event>> getEvents() async {
    try {
      final url = Uri.parse('$baseUrl/events');

      AppLog.d('Fetching events from: $url');

      final response = await Http.client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      AppLog.d('Response status: ${response.statusCode}');
      Session.checkResponse(response);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Event.listFromJson(data);
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      AppLog.e('Failed to fetch events', e);
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Fetch upcoming events (future dates, sorted ascending by date).
  static Future<List<Event>> getUpcomingEvents() async {
    try {
      final url = Uri.parse('$baseUrl/events/upcoming');

      AppLog.d('Fetching upcoming events from: $url');

      final response = await Http.client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      AppLog.d('Response status: ${response.statusCode}');
      Session.checkResponse(response);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Event.listFromJson(data);
      } else {
        throw Exception('Failed to load upcoming events');
      }
    } catch (e) {
      AppLog.e('Failed to fetch upcoming events', e);
      if (e.toString().contains('Exception:')) rethrow;
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

      AppLog.d('Fetching ticket availability from: $url');

      final response = await Http.client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      AppLog.d('Ticket availability status: ${response.statusCode}');
      Session.checkResponse(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        final sortedRaw =
            (body['eventsSortedByAvailability'] as List<dynamic>?) ?? [];
        final fullyBookedRaw =
            (body['fullyBookedEvents'] as List<dynamic>?) ?? [];

        return [
          ..._parseAvailability(sortedRaw, fullyBooked: false),
          ..._parseAvailability(fullyBookedRaw, fullyBooked: true),
        ];
      } else {
        throw Exception('Failed to load ticket availability');
      }
    } catch (e) {
      AppLog.e('Failed to fetch ticket availability', e);
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Fetch a single event by ID
  static Future<Event> getEventById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/events/$id');

      AppLog.d('Fetching event from: $url');

      final response = await Http.client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      AppLog.d('Response status: ${response.statusCode}');
      Session.checkResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Event not found');
      } else {
        throw Exception('Failed to load event');
      }
    } catch (e) {
      AppLog.e('Failed to fetch event', e);
      if (e.toString().contains('Exception:')) rethrow;
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

      AppLog.d('Searching events from: $url');

      final response = await Http.client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      AppLog.d('Search response status: ${response.statusCode}');
      Session.checkResponse(response);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Event.listFromJson(data);
      } else {
        throw Exception('Failed to search events');
      }
    } catch (e) {
      AppLog.e('Failed to search events', e);
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Builds availability rows, skipping any record the server sent malformed.
  static List<EventAvailability> _parseAvailability(
    List<dynamic> raw, {
    required bool fullyBooked,
  }) {
    final rows = <EventAvailability>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final capacity = _asInt(item['capacity']);
        rows.add(EventAvailability(
          event: Event.fromJson(item),
          // A fully booked event has booked == capacity by definition.
          bookedTickets:
              fullyBooked ? capacity : _asInt(item['bookedTickets']),
          capacity: capacity,
          isFullyBooked: fullyBooked,
        ));
      } catch (e) {
        AppLog.e('Skipping malformed availability record', e);
      }
    }
    return rows;
  }

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}