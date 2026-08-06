import 'package:flutter_test/flutter_test.dart';
import 'package:tripnest/src/models/event.dart';

void main() {
  group('Event.fromJson', () {
    test('parses a well-formed record', () {
      final event = Event.fromJson({
        'id': 'evt-1',
        'title': 'Loi Krathong',
        'location': 'Riverside, Chiang Rai',
        'date': '2026-11-24T18:00:00.000Z',
        'price': 450,
        'description': 'Lantern festival',
        'capacity': 200,
        'availableTickets': 12,
        'bookedTickets': 188,
      });

      expect(event.id, 'evt-1');
      expect(event.title, 'Loi Krathong');
      expect(event.shortLocation, 'Chiang Rai');
      expect(event.priceBaht, 450);
      expect(event.capacity, 200);
      expect(event.availableTickets, 12);
      expect(event.date.year, 2026);
    });

    test('does not throw on an empty date string', () {
      // A bare DateTime.parse('') used to throw a FormatException here, which
      // escaped the service and wiped the entire event list.
      expect(() => Event.fromJson({'id': 'x', 'date': ''}), returnsNormally);
    });

    test('falls back to now when the date is unusable', () {
      final before = DateTime.now();
      final event = Event.fromJson({'id': 'x', 'date': 'not-a-date'});
      expect(event.date.isBefore(before.subtract(const Duration(seconds: 5))),
          isFalse);
    });

    test('accepts numeric fields sent as strings', () {
      final event = Event.fromJson({
        'id': 7, // server sometimes sends an int id
        'price': '450',
        'capacity': '200',
        'availableTickets': '0',
      });

      expect(event.id, '7');
      expect(event.priceBaht, 450);
      expect(event.capacity, 200);
      expect(event.availableTickets, 0);
    });

    test('tolerates non-numeric price and null optional counts', () {
      final event = Event.fromJson({'id': 'x', 'price': '-'});

      expect(event.priceBaht, 0);
      expect(event.capacity, isNull);
      expect(event.availableTickets, isNull);
    });

    test('accepts an epoch-millis date', () {
      final event = Event.fromJson({'id': 'x', 'date': 1764000000000});
      expect(event.date.millisecondsSinceEpoch, 1764000000000);
    });
  });

  group('Event.listFromJson', () {
    test('keeps the good records and drops only the broken one', () {
      final events = Event.listFromJson([
        {'id': 'a', 'title': 'A', 'date': '2026-01-01T00:00:00.000Z'},
        'not a map', // wrong shape entirely
        {'id': 'b', 'title': 'B', 'date': ''}, // survives via tryParse
        {'id': 'c', 'title': 'C'},
      ]);

      expect(events.map((e) => e.id), ['a', 'b', 'c']);
    });

    test('returns an empty list for an empty payload', () {
      expect(Event.listFromJson(const []), isEmpty);
    });
  });
}
