import 'package:intl/intl.dart';

class AppFormat {
  static const List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static const List<String> weekdays = [
    'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
  ];

  static const Duration nepalOffset = Duration(hours: 5, minutes: 45);

  static DateTime toNepalTime(DateTime utcOrLocal) {
    return utcOrLocal.toUtc().add(nepalOffset);
  }

  static DateTime? parseDateTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final parsed = DateTime.parse(s);
      return toNepalTime(parsed);
    } catch (_) {
      return null;
    }
  }

  static String formatDate(String? s) {
    if (s == null || s.isEmpty) return '—';
    try {
      if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
        final parts = s.substring(0, 10).split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return '$d ${months[m - 1]} $y';
      }
      final dt = parseDateTime(s);
      if (dt == null) return s;
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return s;
    }
  }

  static String formatDateShort(String? s) {
    if (s == null || s.isEmpty) return '—';
    try {
      if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
        final parts = s.substring(0, 10).split('-');
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return '$d ${months[m - 1]}';
      }
      final dt = parseDateTime(s);
      if (dt == null) return s;
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return s;
    }
  }

  static String weekdayShort(String s) {
    try {
      final parts = s.substring(0, 10).split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      final dt = DateTime.utc(y, m, d);
      return days[dt.weekday % 7];
    } catch (_) {
      return '';
    }
  }

  static String formatTime(String? s) {
    if (s == null || s.isEmpty) return '—';
    final dt = parseDateTime(s);
    if (dt == null) return s;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }

  static String formatDateTime(String? s) {
    if (s == null || s.isEmpty) return '—';
    final dt = parseDateTime(s);
    if (dt == null) return s;
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${formatTime(s)}';
  }

  static String formatDayLabel(String s) {
    final dt = parseDateTime(s);
    if (dt == null) return s;
    final dow = days[dt.weekday % 7];
    return '$dow, ${dt.day} ${months[dt.month - 1]}';
  }

  static String timeAgo(String s) {
    try {
      final dt = DateTime.parse(s).toUtc();
      final diff = DateTime.now().toUtc().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      final nTime = toNepalTime(dt);
      return '${nTime.day} ${months[nTime.month - 1]} ${nTime.year}';
    } catch (_) {
      return s;
    }
  }

  static String money(dynamic v) {
    final n = num.tryParse(v?.toString() ?? '0') ?? 0;
    final formatter = NumberFormat('#,##,###.##', 'en_IN');
    final formatted = formatter.format(n);
    return 'Rs. $formatted';
  }

  static String greeting() {
    final now = toNepalTime(DateTime.now());
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String todayKey() {
    final now = toNepalTime(DateTime.now());
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String todayWeekday() {
    final now = toNepalTime(DateTime.now());
    return weekdays[now.weekday % 7];
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String titleCase(String? s) {
    if (s == null || s.isEmpty) return '';
    return s.replaceAll(RegExp(r'[_-]+'), ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
