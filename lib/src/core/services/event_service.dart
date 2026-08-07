import 'dart:convert';

import 'package:http/http.dart' as http;

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

  /// Statuses that mean "the host is not ready yet", not "your request is
  /// wrong". The API runs on a tier that spins the instance down when idle and
  /// answers these while it wakes.
  static const Set<int> _retryableStatuses = {502, 503, 504};

  /// Delay before each retry. Two attempts after the first, so a waking host
  /// costs a slower load instead of an error screen.
  static const List<Duration> _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  /// GETs [url], retrying while the host reports it is still waking up.
  ///
  /// Runs [Session.checkResponse] on the final response; callers handle the
  /// remaining status codes themselves.
  static Future<http.Response> _get(Uri url) async {
    var response = await Http.client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    for (final delay in _retryDelays) {
      if (!_retryableStatuses.contains(response.statusCode)) break;
      AppLog.d('$url returned ${response.statusCode}, retrying in $delay');
      await Future.delayed(delay);
      response = await Http.client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
    }

    Session.checkResponse(response);
    return response;
  }

  /// Message for a non-200 response. Keeps the status code so a 404 (wrong
  /// path) is distinguishable from a 502 (host asleep) in the field — these
  /// used to collapse into one unhelpful string.
  static String _failure(String what, http.Response response) =>
      'Failed to load $what (HTTP ${response.statusCode})';

  /// Fetch all events
  static Future<List<Event>> getEvents() async {
    try {
      final url = Uri.parse('$baseUrl/events');

      AppLog.d('Fetching events from: $url');

      final response = await _get(url);

      AppLog.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Event.listFromJson(data);
      } else {
        throw Exception(_failure('events', response));
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

      final response = await _get(url);

      AppLog.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Event.listFromJson(data);
      } else {
        throw Exception(_failure('upcoming events', response));
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

      final response = await _get(url);

      AppLog.d('Ticket availability status: ${response.statusCode}');

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
        throw Exception(_failure('ticket availability', response));
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

      final response = await _get(url);

      AppLog.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Event not found');
      } else {
        throw Exception(_failure('event', response));
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

      final response = await _get(url);

      AppLog.d('Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Event.listFromJson(data);
      } else {
        throw Exception(_failure('search results', response));
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