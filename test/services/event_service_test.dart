import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tripnest/src/core/services/event_service.dart';
import 'package:tripnest/src/core/services/http_client.dart';

void main() {
  tearDown(Http.reset);

  void respondWith(String body, {int status = 200}) {
    Http.overrideClient(
      MockClient((_) async => http.Response(body, status,
          headers: {'content-type': 'application/json'})),
    );
  }

  group('EventService.getEvents', () {
    test('returns the parsed events', () async {
      respondWith(jsonEncode([
        {'id': 'a', 'title': 'A', 'date': '2026-01-01T00:00:00.000Z'},
        {'id': 'b', 'title': 'B', 'date': '2026-02-01T00:00:00.000Z'},
      ]));

      final events = await EventService.getEvents();

      expect(events.map((e) => e.id), ['a', 'b']);
    });

    test('keeps the good events when one record is malformed', () async {
      // Regression: a single bad record used to throw out of Event.fromJson,
      // so the whole response was reported as a network error and the user
      // saw zero events.
      respondWith(jsonEncode([
        {'id': 'a', 'title': 'A', 'date': '2026-01-01T00:00:00.000Z'},
        'garbage',
        {'id': 'c', 'title': 'C', 'date': ''},
      ]));

      final events = await EventService.getEvents();

      expect(events.map((e) => e.id), ['a', 'c']);
    });

    test('reports a failure status as an exception', () async {
      respondWith('{}', status: 500);

      expect(EventService.getEvents(), throwsA(isA<Exception>()));
    });
  });

  group('EventService.getEventById', () {
    test('surfaces a 404 as "Event not found", not a network error', () async {
      respondWith('{"message":"nope"}', status: 404);

      await expectLater(
        EventService.getEventById('missing'),
        throwsA(predicate(
            (e) => e.toString().contains('Event not found'))),
      );
    });
  });

  group('EventService.getEventsByTicketAvailability', () {
    test('flags fully booked events and computes remaining seats', () async {
      respondWith(jsonEncode({
        'eventsSortedByAvailability': [
          {
            'id': 'open',
            'title': 'Open',
            'date': '2026-05-01T00:00:00.000Z',
            'capacity': 100,
            'bookedTickets': 40,
          },
        ],
        'fullyBookedEvents': [
          {
            'id': 'full',
            'title': 'Full',
            'date': '2026-05-02T00:00:00.000Z',
            'capacity': 50,
          },
        ],
      }));

      final rows = await EventService.getEventsByTicketAvailability();

      expect(rows, hasLength(2));

      final open = rows.firstWhere((r) => r.event.id == 'open');
      expect(open.isFullyBooked, isFalse);
      expect(open.bookedTickets, 40);
      expect(open.bookedPercentage, 40);

      final full = rows.firstWhere((r) => r.event.id == 'full');
      expect(full.isFullyBooked, isTrue);
      // A fully booked event has booked == capacity by definition.
      expect(full.bookedTickets, 50);
      expect(full.bookedPercentage, 100);
    });

    test('skips malformed availability rows', () async {
      respondWith(jsonEncode({
        'eventsSortedByAvailability': [
          'garbage',
          {
            'id': 'ok',
            'title': 'Ok',
            'date': '2026-05-01T00:00:00.000Z',
            'capacity': '10',
            'bookedTickets': '3',
          },
        ],
      }));

      final rows = await EventService.getEventsByTicketAvailability();

      expect(rows, hasLength(1));
      expect(rows.single.capacity, 10);
      expect(rows.single.bookedTickets, 3);
    });
  });
}
