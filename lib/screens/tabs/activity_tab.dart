import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui_components.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  static const int weeks = 15;
  static const int dayMs = 86400000;

  List<List<({String date, bool visited, bool future})>> _buildGrid(Set<String> visits) {
    final todayStr = AppFormat.todayKey();
    final today = DateTime.parse('${todayStr}T00:00:00Z');
    final end = today.millisecondsSinceEpoch + (6 - (today.weekday % 7)) * dayMs;
    final start = end - (weeks * 7 - 1) * dayMs;

    final cols = <List<({String date, bool visited, bool future})>>[];
    for (int w = 0; w < weeks; w++) {
      final col = <({String date, bool visited, bool future})>[];
      for (int d = 0; d < 7; d++) {
        final currentDt = DateTime.fromMillisecondsSinceEpoch(start + (w * 7 + d) * dayMs, isUtc: true);
        final dateStr = '${currentDt.year}-${currentDt.month.toString().padLeft(2, '0')}-${currentDt.day.toString().padLeft(2, '0')}';
        col.add((
          date: dateStr,
          visited: visits.contains(dateStr),
          future: dateStr.compareTo(todayStr) > 0,
        ));
      }
      cols.add(col);
    }
    return cols;
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
    final grid = _buildGrid(visitSet);
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
              const ScreenTitle(title: 'Activity', subtitle: 'Your gym visits and streaks'),
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

              // Heatmap Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consistency',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your gym visits over the last $weeks weeks',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Grid Columns
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: grid.map((col) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: Column(
                              children: col.map((cell) {
                                final isToday = cell.date == todayKey;
                                return AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: cell.visited
                                          ? AppColors.primary
                                          : cell.future
                                              ? Colors.transparent
                                              : AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(3),
                                      border: isToday
                                          ? Border.all(color: AppColors.accent, width: 2)
                                          : cell.future
                                              ? Border.all(color: AppColors.border, width: 0.8)
                                              : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Legend
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'No visit',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Visited',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
