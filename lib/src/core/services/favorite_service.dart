import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_log.dart';
import 'auth_service.dart';
import 'http_client.dart';
import '../config/api_endpoints.dart';

class FavoriteService {
  static const String baseUrl = ApiEndpoints.baseUrl;
  static const String _favoritesKey = 'favorite_event_ids';

  /// Serializes every mutation. Two taps in quick succession would otherwise
  /// both read the same list, and the second write would drop the first's
  /// change (read-modify-write race).
  static Future<void> _mutations = Future.value();

  static Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _mutations = _mutations.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// Get all favorite event IDs from local storage
  static Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson == null || favoritesJson.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      AppLog.e('Failed to decode saved favorites', e);
      return [];
    }
  }

  /// Check if an event is favorited
  static Future<bool> isFavorite(String eventId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(eventId);
  }

  /// Add an event to favorites
  static Future<void> addFavorite(String eventId) {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavoriteIds();
      if (!favorites.contains(eventId)) {
        favorites.add(eventId);
        await prefs.setString(_favoritesKey, jsonEncode(favorites));
      }
      await _syncAddFavoriteToApi(eventId);
    });
  }

  /// Remove an event from favorites
  static Future<void> removeFavorite(String eventId) {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavoriteIds();
      favorites.remove(eventId);
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
      await _syncRemoveFavoriteFromApi(eventId);
    });
  }

  /// Toggle favorite status
  static Future<bool> toggleFavorite(String eventId) async {
    final isFav = await isFavorite(eventId);
    if (isFav) {
      await removeFavorite(eventId);
      return false;
    } else {
      await addFavorite(eventId);
      return true;
    }
  }

  /// Sync add favorite to API. Local storage stays the source of truth, so a
  /// failure here is logged rather than surfaced — but it is no longer
  /// invisible, and it no longer races the local write.
  static Future<void> _syncAddFavoriteToApi(String eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final response = await Http.client.post(
        Uri.parse('$baseUrl/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'eventId': eventId}),
      );
      if (response.statusCode >= 400) {
        AppLog.e('Favorite add did not sync (${response.statusCode})');
      }
    } catch (e) {
      AppLog.e('Favorite add did not sync', e);
    }
  }

  /// Sync remove favorite from API (see [_syncAddFavoriteToApi]).
  static Future<void> _syncRemoveFavoriteFromApi(String eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final response = await Http.client.delete(
        Uri.parse('$baseUrl/favorites/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode >= 400) {
        AppLog.e('Favorite removal did not sync (${response.statusCode})');
      }
    } catch (e) {
      AppLog.e('Favorite removal did not sync', e);
    }
  }

  /// Clear all favorites
  static Future<void> clearFavorites() {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
    });
  }
}
