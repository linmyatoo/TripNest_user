import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripnest/src/core/services/chat_service.dart';
import 'package:tripnest/src/core/services/http_client.dart';

/// One room per event id, each with a distinct room id.
String _roomsBody(List<String> eventIds) => jsonEncode({
      'rooms': [
        for (var i = 0; i < eventIds.length; i++)
          {
            'id': 'room-$i',
            'eventId': eventIds[i],
            'eventTitle': 'Event ${eventIds[i]}',
            'memberCount': 3,
            'createdAt': '2026-08-01T10:00:00.000Z',
          },
      ],
    });

String _bookingsBody(List<Map<String, String>> bookings) => jsonEncode([
      for (final booking in bookings)
        {
          'id': 'bk-${booking['eventId']}',
          'userId': 'user-1',
          'eventId': booking['eventId'],
          'ticketCount': 1,
          'totalPrice': 199,
          'status': booking['status'],
          'createdAt': '2026-08-01T10:00:00.000Z',
          'updatedAt': '2026-08-01T10:00:00.000Z',
        },
    ]);

/// Answers `/chat/rooms` and `/bookings/me`; anything else fails the test.
MockClient _client({
  required String roomsBody,
  required String bookingsBody,
  int roomsStatus = 200,
  int bookingsStatus = 200,
}) {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/chat/rooms')) {
      return http.Response(roomsBody, roomsStatus);
    }
    if (path.endsWith('/bookings/me')) {
      return http.Response(bookingsBody, bookingsStatus);
    }
    return http.Response('{"error":"unexpected ${request.url}"}', 500);
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  tearDown(Http.reset);

  test('keeps only rooms whose event the user booked', () async {
    Http.overrideClient(_client(
      roomsBody: _roomsBody(['evt-booked', 'evt-not-booked']),
      bookingsBody: _bookingsBody([
        {'eventId': 'evt-booked', 'status': 'CONFIRMED'},
      ]),
    ));

    final rooms = await ChatService.getBookedChatRooms();

    expect(rooms.map((room) => room.eventId), ['evt-booked']);
  });

  test('drops rooms whose only booking was cancelled', () async {
    Http.overrideClient(_client(
      roomsBody: _roomsBody(['evt-1']),
      bookingsBody: _bookingsBody([
        {'eventId': 'evt-1', 'status': 'CANCELLED'},
      ]),
    ));

    expect(await ChatService.getBookedChatRooms(), isEmpty);
  });

  test('keeps rooms for pending and completed bookings', () async {
    Http.overrideClient(_client(
      roomsBody: _roomsBody(['evt-pending', 'evt-done']),
      bookingsBody: _bookingsBody([
        {'eventId': 'evt-pending', 'status': 'PENDING'},
        {'eventId': 'evt-done', 'status': 'COMPLETED'},
      ]),
    ));

    final rooms = await ChatService.getBookedChatRooms();

    expect(
      rooms.map((room) => room.eventId).toList()..sort(),
      ['evt-done', 'evt-pending'],
    );
  });

  test('no bookings means no chats', () async {
    Http.overrideClient(_client(
      roomsBody: _roomsBody(['evt-1', 'evt-2']),
      bookingsBody: '[]',
    ));

    expect(await ChatService.getBookedChatRooms(), isEmpty);
  });

  test('a failed bookings fetch throws instead of showing ungated rooms',
      () async {
    Http.overrideClient(_client(
      roomsBody: _roomsBody(['evt-1']),
      bookingsBody: '{"error":"boom"}',
      bookingsStatus: 500,
    ));

    expect(ChatService.getBookedChatRooms(), throwsException);
  });
}
