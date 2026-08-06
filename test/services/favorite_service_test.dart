import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/favorite_service.dart';
import 'package:tripnest/src/core/services/http_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // No token stored → the API sync short-circuits, so these tests exercise
    // the local storage path only.
    Http.overrideClient(MockClient((_) async => http.Response('{}', 200)));
  });

  tearDown(Http.reset);

  test('adds and removes favorites', () async {
    await FavoriteService.addFavorite('evt-1');
    expect(await FavoriteService.getFavoriteIds(), ['evt-1']);
    expect(await FavoriteService.isFavorite('evt-1'), isTrue);

    await FavoriteService.removeFavorite('evt-1');
    expect(await FavoriteService.getFavoriteIds(), isEmpty);
  });

  test('adding the same id twice does not duplicate it', () async {
    await FavoriteService.addFavorite('evt-1');
    await FavoriteService.addFavorite('evt-1');

    expect(await FavoriteService.getFavoriteIds(), ['evt-1']);
  });

  test('concurrent adds do not lose a favorite', () async {
    // Regression: both calls read the same list, then the second write
    // overwrote the first, so one favorite silently vanished.
    await Future.wait([
      FavoriteService.addFavorite('evt-1'),
      FavoriteService.addFavorite('evt-2'),
      FavoriteService.addFavorite('evt-3'),
    ]);

    final ids = await FavoriteService.getFavoriteIds();
    expect(ids..sort(), ['evt-1', 'evt-2', 'evt-3']);
  });

  test('toggle flips the stored state', () async {
    expect(await FavoriteService.toggleFavorite('evt-9'), isTrue);
    expect(await FavoriteService.isFavorite('evt-9'), isTrue);

    expect(await FavoriteService.toggleFavorite('evt-9'), isFalse);
    expect(await FavoriteService.isFavorite('evt-9'), isFalse);
  });

  test('unreadable stored JSON yields an empty list instead of throwing',
      () async {
    SharedPreferences.setMockInitialValues({
      'favorite_event_ids': 'not json at all',
    });

    expect(await FavoriteService.getFavoriteIds(), isEmpty);
  });

  test('reads ids that were stored as numbers', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_event_ids': jsonEncode([1, 2]),
    });

    // A `cast<String>()` on this used to throw a TypeError.
    expect(await FavoriteService.getFavoriteIds(), ['1', '2']);
  });
}
