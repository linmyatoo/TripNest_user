import 'dart:convert';


import '../../models/booking.dart';
import '../utils/app_log.dart';
import 'auth_service.dart';
import 'session.dart';
import 'http_client.dart';
import '../config/api_endpoints.dart';

class BookingService {
  static const String baseUrl = ApiEndpoints.baseUrl;

  /// Get auth token from storage
  static Future<String?> _getToken() => AuthService.getToken();

  /// Fetch all bookings for the authenticated user
  static Future<List<Booking>> getMyBookings() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/bookings/me');

      AppLog.d('Fetching bookings from: $url');

      final response = await Http.client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLog.d('Response status: ${response.statusCode}');
      Session.checkResponse(response);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      AppLog.e('Failed to fetch bookings', e);
      if (e.toString().contains('Exception:')) rethrow;
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

      AppLog.d('Fetching booking from: $url');

      final response = await Http.client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLog.d('Response status: ${response.statusCode}');
      Session.checkResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data);
      } else {
        throw Exception('Failed to load booking');
      }
    } catch (e) {
      AppLog.e('Failed to fetch booking', e);
      if (e.toString().contains('Exception:')) rethrow;
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

      AppLog.d('Confirming booking at: $url');

      final response = await Http.client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLog.d('Response status: ${response.statusCode}');
      Session.checkResponse(response);

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
      AppLog.e('Failed to confirm booking', e);
      if (e.toString().contains('Exception:')) rethrow;
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
        AppLog.d('No auth token found');
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/bookings');

      AppLog.d('Creating booking at: $url');

      final payload = <String, dynamic>{
        'eventId': eventId,
        'ticketCounts': ticketCounts,
      };
      if (totalPrice != null) {
        payload['totalPrice'] = totalPrice;
      }

      final response = await Http.client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      AppLog.d('Response status: ${response.statusCode}');
      Session.checkResponse(response);

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
      AppLog.e('Failed to create booking', e);
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
