import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/auth_service.dart';
import 'package:tripnest/src/core/services/http_client.dart';

/// Answers `/auth/login` with [body]; anything else fails the test.
MockClient _loginClient(String body, {int status = 200}) {
  return MockClient((request) async {
    if (request.url.path.endsWith('/auth/login')) {
      return http.Response(body, status);
    }
    return http.Response('{"error":"unexpected ${request.url}"}', 500);
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Http.reset);

  group('login', () {
    test('stores the session when the response carries a token', () async {
      Http.overrideClient(_loginClient(jsonEncode({
        'token': 'jwt-123',
        'user': {'id': 'u-1', 'name': 'Ada', 'email': 'ada@example.com'},
      })));

      await AuthService.login(email: 'ada@example.com', password: 'pw');

      expect(await AuthService.getToken(), 'jwt-123');
      expect(await AuthService.getUserId(), 'u-1');
      expect(await AuthService.isLoggedIn(), isTrue);
    });

    test('rejects a 200 that carries no token', () async {
      // The screen used to navigate into the app on this response, leaving
      // every authenticated call failing with "Not authenticated".
      Http.overrideClient(_loginClient(jsonEncode({
        'message': 'Login successful',
        'user': {'id': 'u-1'},
      })));

      await expectLater(
        AuthService.login(email: 'ada@example.com', password: 'pw'),
        throwsA(predicate((e) => e.toString().contains('did not return a token'))),
      );

      expect(await AuthService.isLoggedIn(), isFalse);
    });

    test('reads a token nested under data', () async {
      Http.overrideClient(_loginClient(jsonEncode({
        'data': {
          'token': 'jwt-nested',
          'user': {'id': 'u-9', 'email': 'nested@example.com'},
        },
      })));

      await AuthService.login(email: 'nested@example.com', password: 'pw');

      expect(await AuthService.getToken(), 'jwt-nested');
    });

    test('surfaces the server message on a failed login', () async {
      Http.overrideClient(_loginClient(
        jsonEncode({'message': 'Invalid credentials'}),
        status: 401,
      ));

      await expectLater(
        AuthService.login(email: 'ada@example.com', password: 'wrong'),
        throwsA(predicate((e) => e.toString().contains('Invalid credentials'))),
      );

      expect(await AuthService.isLoggedIn(), isFalse);
    });
  });
}
