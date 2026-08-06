import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/air_quality_service.dart';
import 'package:tripnest/src/core/services/auth_service.dart';
import 'package:tripnest/src/core/services/favorite_service.dart';
import 'package:tripnest/src/core/services/notification_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      // session
      'auth_token': 'jwt-for-user-a',
      'user_id': 'user-a',
      'username': 'usera',
      'name': 'User A',
      'email': 'a@example.com',
      'role': 'user',
      // per-user data that used to survive a logout
      'favorite_event_ids': jsonEncode(['evt-1', 'evt-2']),
      'app_notifications': jsonEncode([
        {
          'id': '1',
          'title': 'Booking confirmed',
          'body': 'See you there',
          'createdAt': '2026-08-01T00:00:00.000Z',
          'isRead': false,
        }
      ]),
      'cached_aqi_data': jsonEncode({'aqi': 55, 'cityName': 'Chiang Rai'}),
      'last_pm25_value': 30.0,
      'last_aqi_check_date': '2026-8-1',
      // a device-level preference that must NOT be wiped
      'notifications_enabled': false,
    });
  });

  test('logout clears the session', () async {
    expect(await AuthService.isLoggedIn(), isTrue);

    await AuthService.logout();

    expect(await AuthService.isLoggedIn(), isFalse);
    expect(await AuthService.getToken(), isNull);
    expect(await AuthService.getUserId(), isNull);
  });

  test('logout clears per-user data so the next account cannot see it',
      () async {
    // Regression: logout only removed the auth keys, so user B logged in and
    // saw user A's favorites and booking notifications.
    expect(await FavoriteService.getFavoriteIds(), isNotEmpty);
    expect(await NotificationService.getNotifications(), isNotEmpty);
    expect(await AirQualityService.getCachedAqi(), isNotNull);

    await AuthService.logout();

    expect(await FavoriteService.getFavoriteIds(), isEmpty);
    expect(await NotificationService.getNotifications(), isEmpty);
    expect(await AirQualityService.getCachedAqi(), isNull);
    expect(await AirQualityService.getCachedPm25(), isNull);
  });

  test('logout keeps device-level notification preferences', () async {
    await AuthService.logout();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isFalse);
  });
}
