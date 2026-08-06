import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/main.dart';
import 'package:tripnest/src/core/services/http_client.dart';
import 'package:tripnest/src/features/splash/admin_splash_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The app must never reach the real backend from a test.
    Http.overrideClient(MockClient((_) async => http.Response('[]', 200)));
  });

  tearDown(Http.reset);

  testWidgets('app starts on the splash page, not inside the shell',
      (tester) async {
    // Regression: initialRoute pointed straight at AppShell, so the login
    // check never ran and a fresh install landed in a logged-in-looking app
    // (which also spun up the real polling timers in this test).
    await tester.pumpWidget(const TripNestApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AdminSplashPage), findsOneWidget);
    expect(find.text('TripNest'), findsOneWidget);

    // Let the splash's delayed navigation fire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('an unauthenticated user is sent to onboarding', (tester) async {
    await tester.pumpWidget(const TripNestApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(AdminSplashPage), findsNothing);
  });
}
