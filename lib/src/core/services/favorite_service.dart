import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class FavoriteService {
  static const String baseUrl = 'https://naylinhtet.me/api';
  static const String _favoritesKey = 'favorite_event_ids';

  /// Get all favorite event IDs from local storage
  static Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    print('FavoriteService.getFavoriteIds - Raw JSON: $favoritesJson'); // Debug
    if (favoritesJson == null || favoritesJson.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      final result = decoded.cast<String>();
      print('FavoriteService.getFavoriteIds - Decoded: $result'); // Debug
      return result;
    } catch (e) {
      print('FavoriteService.getFavoriteIds - Error decoding: $e'); // Debug
      return [];
    }
  }

  /// Check if an event is favorited
  static Future<bool> isFavorite(String eventId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(eventId);
  }

  /// Add an event to favorites
  static Future<void> addFavorite(String eventId) async {
    print('FavoriteService.addFavorite - Adding: $eventId'); // Debug
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteIds();
    if (!favorites.contains(eventId)) {
      favorites.add(eventId);
      final jsonString = jsonEncode(favorites);
      print('FavoriteService.addFavorite - Saving JSON: $jsonString'); // Debug
      await prefs.setString(_favoritesKey, jsonString);

      // Verify save
      final verify = prefs.getString(_favoritesKey);
      print('FavoriteService.addFavorite - Verified saved: $verify'); // Debug
    } else {
      print('FavoriteService.addFavorite - Already exists'); // Debug
    }

    // Also try to sync with API (fire and forget)
    _syncAddFavoriteToApi(eventId);
  }

  /// Remove an event from favorites
  static Future<void> removeFavorite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteIds();
    favorites.remove(eventId);
    await prefs.setString(_favoritesKey, jsonEncode(favorites));

    // Also try to sync with API (fire and forget)
    _syncRemoveFavoriteFromApi(eventId);
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

  /// Sync add favorite to API (optional - won't fail if API unavailable)
  static Future<void> _syncAddFavoriteToApi(String eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'eventId': eventId}),
      );
    } catch (_) {
      // Silently fail - local storage is the source of truth
    }
  }

  /// Sync remove favorite from API (optional - won't fail if API unavailable)
  static Future<void> _syncRemoveFavoriteFromApi(String eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      await http.delete(
        Uri.parse('$baseUrl/favorites/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      // Silently fail - local storage is the source of truth
    }
  }

  /// Clear all favorites
  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}
