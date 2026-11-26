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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});


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
        onRefresh: () => gym.fetchNotifications(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: 'Notifications',
                onBack: () => Navigator.pop(context),
                right: unreadCount > 0
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
              const SizedBox(height: 16),

              if (gym.isLoadingNotifications && notifications.isEmpty)
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
