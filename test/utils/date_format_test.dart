import 'package:flutter_test/flutter_test.dart';
import 'package:tripnest/src/core/utils/date_format.dart';

void main() {
  group('AppDate month names', () {
    test('maps valid months', () {
      expect(AppDate.monthShort(1), 'Jan');
      expect(AppDate.monthShort(12), 'Dec');
      expect(AppDate.monthLong(1), 'January');
      expect(AppDate.monthLong(12), 'December');
    });

    test('returns empty rather than throwing on an out-of-range month', () {
      // The old inline `months[m - 1]` arrays threw a RangeError here.
      expect(AppDate.monthShort(0), '');
      expect(AppDate.monthShort(13), '');
      expect(AppDate.monthLong(-1), '');
    });
  });

  group('AppDate.relative', () {
    final now = DateTime.parse('2026-08-06T12:00:00.000Z');

    test('formats each band', () {
      expect(AppDate.relative(now, now: now), 'Just now');
      expect(
          AppDate.relative(now.subtract(const Duration(seconds: 30)), now: now),
          'Just now');
      expect(AppDate.relative(now.subtract(const Duration(minutes: 5)), now: now),
          '5m ago');
      expect(AppDate.relative(now.subtract(const Duration(hours: 3)), now: now),
          '3h ago');
      expect(AppDate.relative(now.subtract(const Duration(days: 2)), now: now),
          '2d ago');
    });

    test('falls back to an absolute date past a week', () {
      final old = DateTime(2026, 7, 1);
      expect(AppDate.relative(old, now: now), '1/7/2026');
    });

    test('treats a future timestamp as "Just now" instead of a negative age',
        () {
      expect(AppDate.relative(now.add(const Duration(hours: 2)), now: now),
          'Just now');
    });
  });

  group('AppDate formatting', () {
    final date = DateTime(2026, 11, 24);

    test('renders the documented shapes', () {
      expect(AppDate.dayMonthYear(date), '24 Nov 2026');
      expect(AppDate.longDate(date), 'November 24, 2026');
      expect(AppDate.numericDate(date), '24/11/2026');
    });
  });
}
