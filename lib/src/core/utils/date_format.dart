/// Shared date/time formatting.
///
/// These helpers existed as near-identical copies in four pages (month-name
/// arrays three times, relative-time formatting four times), which is how the
/// wordings drifted apart.
class AppDate {
  AppDate._();

  static const List<String> monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> monthsLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// `1` → `Jan`. Out-of-range months return an empty string rather than
  /// throwing a RangeError.
  static String monthShort(int month) =>
      (month >= 1 && month <= 12) ? monthsShort[month - 1] : '';

  /// `1` → `January`.
  static String monthLong(int month) =>
      (month >= 1 && month <= 12) ? monthsLong[month - 1] : '';

  /// `24 Nov 2026`
  static String dayMonthYear(DateTime date) =>
      '${date.day} ${monthShort(date.month)} ${date.year}';

  /// `November 24, 2026`
  static String longDate(DateTime date) =>
      '${monthLong(date.month)} ${date.day}, ${date.year}';

  /// `24/11/2026`
  static String numericDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  /// `Just now`, `5m ago`, `3h ago`, `2d ago`, then an absolute date.
  static String relative(DateTime from, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(from);
    if (diff.isNegative) return 'Just now';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return numericDate(from);
  }
}
