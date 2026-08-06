import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session.dart';
import 'http_client.dart';
import '../config/api_endpoints.dart';

class ReviewService {
  static const String baseUrl = ApiEndpoints.baseUrl;

  /// Get auth token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Submit a review for an event
  static Future<void> submitReview({
    required String eventId,
    required int rating,
    String? comment,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('$baseUrl/reviews');

      debugPrint('Submitting review to: $url');

      final body = <String, dynamic>{
        'eventId': eventId,
        'rating': rating,
      };
      if (comment != null && comment.isNotEmpty) {
        body['comment'] = comment;
      }

      final response = await Http.client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final data =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final message = data is Map<String, dynamic> &&
                (data['message'] ?? data['error']) != null
            ? (data['message'] ?? data['error']) as String
            : 'Failed to submit review';
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific event
  static Future<List<Review>> getEventReviews(String eventId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/reviews/event/$eventId');
      debugPrint('Fetching reviews from: $url');

      final response = await Http.client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Reviews response status: ${response.statusCode}');
      debugPrint('Reviews response body: ${response.body}');

      Session.checkResponse(response);


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Parsed reviews data type: ${data.runtimeType}');
        if (data is List) {
          final reviews = data
              .whereType<Map<String, dynamic>>()
              .map((r) => Review.fromJson(r))
              .toList();
          debugPrint('Parsed ${reviews.length} reviews');
          return reviews;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  /// Get average rating for a specific event
  static Future<double?> getEventAverageRating(String eventId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/reviews/event/$eventId/rating');
      debugPrint('Fetching average rating from: $url');

      final response = await Http.client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Average rating response status: ${response.statusCode}');

      Session.checkResponse(response);


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final rating = data['averageRating'];
          if (rating != null) {
            return (rating as num).toDouble();
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching average rating: $e');
      return null;
    }
  }
}

/// Review model
class Review {
  final String id;
  final String eventId;
  final String userId;
  final int rating;
  final String? comment;
  final String? sentimentLabel;
  final double? sentimentScore;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    this.comment,
    this.sentimentLabel,
    this.sentimentScore,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      sentimentLabel: json['sentimentLabel'] as String?,
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
