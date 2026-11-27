import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/engagement_widgets.dart';
import '../../widgets/ui_components.dart';

({IconData icon, Color color, Color bg}) notificationTypeStyle(String? type) {
  switch (type) {
    case 'expiry':
      return (icon: Icons.hourglass_top_outlined, color: AppColors.warning, bg: AppColors.warningSoft);
    case 'billing':
      return (icon: Icons.receipt_long_outlined, color: AppColors.info, bg: AppColors.infoSoft);
    case 'visit':
      return (icon: Icons.directions_walk_outlined, color: AppColors.success, bg: AppColors.successSoft);
    case 'freeze':
      return (icon: Icons.ac_unit, color: kFreeze, bg: kFreezeSoft);
    case 'award':
      return (icon: Icons.emoji_events_outlined, color: kGold, bg: kGoldSoft);
    case 'event':
      return (icon: Icons.event_outlined, color: kIndigo, bg: kIndigoSoft);
    case 'notice':
      return (icon: Icons.campaign_outlined, color: AppColors.info, bg: AppColors.infoSoft);
    default:
      return (icon: Icons.campaign_outlined, color: AppColors.primary, bg: AppColors.primarySoft);
  }
}

class NotificationsScreen extends StatefulWidget {
  /// 0 = Notifications, 1 = Noticeboard (Member of the Month & gym notices history)
  final int initialTab;

  const NotificationsScreen({super.key, this.initialTab = 0});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 1);
  }

  Widget _buildSegmentButton({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
    int flex = 1,
  }) {
    final selected = _tab == index;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_tab != index) {
            HapticFeedback.selectionClick();
            setState(() => _tab = index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAwardHistory(GymProvider gym) {
    final motm = gym.latestMemberOfTheMonth;
    final awardNotifications = gym.notifications.where((n) => n.type == 'award').toList();

    if (gym.isLoadingNoticeboard && motm == null && awardNotifications.isEmpty) {
      return const [LoadingBlock()];
    }

    if (motm == null && awardNotifications.isEmpty) {
      return const [
        AppCard(
          child: EmptyStateView(
            icon: Icons.emoji_events_outlined,
            title: 'No announcements yet',
            message: 'Monthly award winners and past history will appear here.',
          ),
        ),
      ];
    }

    return [
      if (motm != null) ...[
        MemberOfTheMonthCard(motm: motm),
        const SizedBox(height: 18),
      ],
      if (awardNotifications.isNotEmpty) ...[
        const SectionHeader(title: 'History', icon: Icons.history_rounded),
        const SizedBox(height: 10),
        for (final n in awardNotifications) ...[
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBubble(
                  name: Icons.emoji_events_outlined,
                  color: kGold,
                  bg: kGoldSoft,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.message,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormat.timeAgo(n.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final notifications = gym.notifications;
    final unreadCount = notifications.where((n) => n.status == 'unread').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => Future.wait([
          gym.fetchNotifications(),
          gym.fetchNoticeboard(),
        ]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: _tab == 0 ? 'Notifications' : 'Employee of the Month',
                onBack: () => Navigator.pop(context),
                right: _tab == 0 && unreadCount > 0
                    ? GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await gym.markAllNotificationsRead();
                        },
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),

              // Segmented Switcher: Notifications | Employee of the Month
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(
                      index: 0,
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      badgeCount: unreadCount,
                      flex: 2,
                    ),
                    _buildSegmentButton(
                      index: 1,
                      icon: Icons.emoji_events_outlined,
                      label: 'Employee of the Month',
                      flex: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_tab == 1)
                ..._buildAwardHistory(gym)
              else if (gym.isLoadingNotifications && notifications.isEmpty)
                const LoadingBlock()
              else if (gym.notificationsError != null && notifications.isEmpty)
                ErrorStateView(
                  message: gym.notificationsError,
                  onRetry: () => gym.fetchNotifications(),
                )
              else if (notifications.isEmpty)
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.notifications_off_outlined,
                    title: "You're all caught up",
                    message: 'Reminders about your membership, payments and gym updates show up here.',
                  ),
                )
              else
                ...notifications.map((n) {
                  final isNew = n.status == 'unread';
                  final t = notificationTypeStyle(n.type);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      backgroundColor: isNew ? const Color(0xFFF7FAFE) : AppColors.surface,
                      borderColor: isNew ? const Color(0xFFC9DDF2) : AppColors.border,
                      onTap: isNew
                          ? () async {
                              await gym.markNotificationRead(n.id);
                            }
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconBubble(
                            name: t.icon,
                            color: t.color,
                            bg: t.bg,
                            size: 40,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                    if (isNew) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.message,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppFormat.timeAgo(n.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
