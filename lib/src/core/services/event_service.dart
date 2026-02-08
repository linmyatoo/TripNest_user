import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/event.dart';

class EventService {
  static const String baseUrl = 'https://naylinhtet.me/api';

  /// Fetch all events
  static Future<List<Event>> getEvents() async {
    try {
      final url = Uri.parse('$baseUrl/events');

      print('Fetching events from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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

  /// Fetch upcoming events (future dates, sorted ascending)
  static Future<List<Event>> getUpcomingEvents() async {
    try {
      final url = Uri.parse('$baseUrl/events/upcoming');

      print('Fetching upcoming events from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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

  /// Fetch a single event by ID
  static Future<Event> getEventById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/events/$id');

      print('Fetching event from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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

      final url = Uri.parse('$baseUrl/events/search').replace(queryParameters: queryParams);

      print('Searching events from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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
