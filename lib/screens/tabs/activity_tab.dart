import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui_components.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  late DateTime _displayedMonth;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final today = DateTime.parse('${AppFormat.todayKey()}T00:00:00Z');
    _currentMonth = DateTime.utc(today.year, today.month, 1);
    _displayedMonth = _currentMonth;
  }

  bool get _canGoNext =>
      _displayedMonth.year < _currentMonth.year ||
      (_displayedMonth.year == _currentMonth.year && _displayedMonth.month < _currentMonth.month);

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime.utc(_displayedMonth.year, _displayedMonth.month + delta, 1);
    });
  }

  Widget _buildCalendarCard(Set<String> visitSet, String todayKey) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    // Sunday = 0, Monday = 1, ..., Saturday = 6
    final leadingBlanks = DateTime.utc(year, month, 1).weekday % 7;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    final monthPrefix = '$year-${month.toString().padLeft(2, '0')}-';
    final visitsInMonth = visitSet.where((d) => d.startsWith(monthPrefix)).length;
    final monthTitle = DateFormat('MMMM yyyy').format(_displayedMonth);
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Header + Navigation
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$visitsInMonth visit${visitsInMonth == 1 ? '' : 's'} logged',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _monthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              const SizedBox(width: 6),
              _monthNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: _canGoNext ? () => _changeMonth(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Labels
          Row(
            children: weekdays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Weeks
          for (int row = 0; row < totalCells ~/ 7; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - leadingBlanks + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 36));
                  }

                  final dateKey = '$monthPrefix${dayNum.toString().padLeft(2, '0')}';
                  final visited = visitSet.contains(dateKey);
                  final isToday = dateKey == todayKey;
                  final isFuture = dateKey.compareTo(todayKey) > 0;

                  return Expanded(
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: visited
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primarySoft
                                  : Colors.transparent,
                          border: isToday
                              ? Border.all(
                                  color: visited ? AppColors.accent : AppColors.primary,
                                  width: 1.8,
                                )
                              : null,
                        ),
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: visited || isToday ? FontWeight.w700 : FontWeight.w500,
                            color: visited
                                ? Colors.white
                                : isToday
                                    ? AppColors.primary
                                    : isFuture
                                        ? AppColors.textFaint
                                        : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Legend
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Visited',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Today',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthNavButton({required IconData icon, VoidCallback? onTap}) {
    final disabled = onTap == null;
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: disabled ? AppColors.textFaint : AppColors.text,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (gym.isLoadingAttendance && gym.attendance == null) {
      return const Scaffold(body: LoadingBlock());
    }

    if (gym.attendanceError != null && gym.attendance == null) {
      return Scaffold(
        body: ErrorStateView(
          message: gym.attendanceError,
          onRetry: () => gym.fetchAttendance(),
        ),
      );
    }

    final attendance = gym.attendance;
    final visitSet = (attendance?.visitDates ?? []).toSet();
    final todayKey = AppFormat.todayKey();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => gym.fetchAttendance(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenTitle(title: 'Check-ins', subtitle: 'Your gym visits and streaks'),
              const SizedBox(height: 16),

              // Stat Tiles
              Row(
                children: [
                  StatTile(
                    icon: Icons.local_fire_department,
                    label: 'Day visit streak',
                    value: '${attendance?.streak ?? 0}',
                    tint: const Color(0xFFE8590C),
                    bg: const Color(0xFFFFEDE0),
                  ),
                  const SizedBox(width: 10),
                  StatTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Visits this month',
                    value: '${attendance?.thisMonth ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Monthly Visit Calendar Card
              _buildCalendarCard(visitSet, todayKey),
              const SizedBox(height: 24),

              // Recent Visits
              const Text(
                'Recent visits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              if (attendance == null || attendance.recent.isEmpty)
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.directions_walk_outlined,
                    title: 'No visits yet',
                    message: 'Your check-ins at the gym gate will show up here.',
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: attendance.recent.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;
                      final isDenied = r.status == 'denied';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: i > 0
                              ? const Border(top: BorderSide(color: AppColors.border, width: 0.8))
                              : null,
                        ),
                        child: Row(
                          children: [
                            IconBubble(
                              name: isDenied ? Icons.cancel_outlined : Icons.login_outlined,
                              color: isDenied ? AppColors.danger : AppColors.primary,
                              bg: isDenied ? AppColors.dangerSoft : AppColors.primarySoft,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppFormat.formatDayLabel(r.checkInTime),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    '${AppFormat.formatTime(r.checkInTime)}${r.checkOutTime != null ? " – ${AppFormat.formatTime(r.checkOutTime)}" : ""}${r.method != null ? " · ${AppFormat.titleCase(r.method)}" : ""}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  if (r.reason != null && r.reason!.isNotEmpty)
                                    Text(
                                      r.reason!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isDenied)
                              const AppBadge(text: 'Denied', tone: BadgeTone.danger),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
