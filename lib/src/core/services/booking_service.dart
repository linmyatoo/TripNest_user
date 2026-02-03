import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/booking.dart';

class BookingService {
  static const String baseUrl = 'https://naylinhtet.me/api';

  /// Get auth token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Fetch all bookings for the authenticated user
  static Future<List<Booking>> getMyBookings() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/bookings/me');

      print('Fetching bookings from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Fetch a single booking by ID
  static Future<Booking> getBookingById(String id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/bookings/$id');

      print('Fetching booking from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data);
      } else {
        throw Exception('Failed to load booking');
      }
    } catch (e) {
      print('Error fetching booking: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Confirm a booking via PATCH /bookings/:id/confirm
  static Future<Booking> confirmBooking(String id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/bookings/$id/confirm');

      print('Confirming booking at: $url');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data);
      } else {
        final body =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final message = body is Map<String, dynamic> && body['message'] != null
            ? body['message'] as String
            : 'Failed to confirm booking';
        throw Exception(message);
      }
    } catch (e) {
      print('Error confirming booking: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Create a booking before confirming payment
  static Future<Booking> createBooking({
    required String eventId,
    int ticketCounts = 1,
    double? totalPrice,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('No auth token found');
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/bookings');

      print('Creating booking at: $url');

      final payload = <String, dynamic>{
        'eventId': eventId,
        'ticketCounts': ticketCounts,
      };
      if (totalPrice != null) {
        payload['totalPrice'] = totalPrice;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data);
      } else {
        final body =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final message = body is Map<String, dynamic> && body['message'] != null
            ? body['message'] as String
            : 'Failed to create booking';
        throw Exception(message);
      }
    } catch (e) {
      print('Error creating booking: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
