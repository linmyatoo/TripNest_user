// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripnest/main.dart';

void main() {
  testWidgets('App test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TripNestApp());

    // Verify that the app builds without crashing
    // Note: We use pump() instead of pumpAndSettle() to avoid waiting
    // for animations and async operations that might fail in tests
    await tester.pump();

    // Check that a MaterialApp widget exists
    expect(find.byType(MaterialApp), findsOneWidget);

    // Clean up any pending timers from splash screen
    await tester.pump(const Duration(milliseconds: 900));
  });
}
