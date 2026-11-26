/// Pure date helpers for membership freeze requests.
/// All dates are calendar dates (`YYYY-MM-DD`) handled as UTC midnight so no
/// timezone/DST shift can move them.
class FreezeUtils {
  static const int maxFreezeDays = 60;

  static DateTime parseYmd(String s) {
    final p = s.substring(0, 10).split('-');
    return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime? tryParseYmd(String? s) {
    if (s == null || s.length < 10) return null;
    try {
      return parseYmd(s);
    } catch (_) {
      return null;
    }
  }

  static DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Inclusive day count: 2026-12-01..2026-12-03 == 3.
  static int inclusiveDays(DateTime start, DateTime end) =>
      dateOnly(end).difference(dateOnly(start)).inDays + 1;

  /// End date of a freeze that starts on [start] and lasts [days] days.
  static DateTime endDateForDays(DateTime start, int days) =>
      dateOnly(start).add(Duration(days: days - 1));

  /// Expiry after an approved freeze of [days] days.
  static DateTime newExpiry(DateTime currentEnd, int days) =>
      dateOnly(currentEnd).add(Duration(days: days));
}
