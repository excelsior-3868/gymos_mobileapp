import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/engagement_widgets.dart';
import '../../widgets/ui_components.dart';
import '../sub_screens/billing_screen.dart';
import '../sub_screens/freeze_request_screen.dart';
import '../sub_screens/membership_screen.dart';
import '../sub_screens/notifications_screen.dart';
import '../sub_screens/referrals_screen.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback onNavigateToTrain;
  final VoidCallback onNavigateToOffers;
  final VoidCallback onNavigateToProfile;

  const HomeTab({
    super.key,
    required this.onNavigateToTrain,
    required this.onNavigateToOffers,
    required this.onNavigateToProfile,
  });

  void _openFreeze(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FreezeRequestScreen()));

  void _openNotifications(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));

  Widget _buildRecentNotification(BuildContext context, NotificationItem n) {
    final t = notificationTypeStyle(n.type);
    final isNew = n.status == 'unread';
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _openNotifications(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(name: t.icon, color: t.color, bg: t.bg, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  n.message,
                  style: const TextStyle(fontSize: 12.5, height: 1.35, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(AppFormat.timeAgo(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);

    if (gym.isLoadingMe && gym.me == null) {
      return const Scaffold(
        body: LoadingBlock(),
      );
    }

    if (gym.meError != null && gym.me == null) {
      return Scaffold(
        body: ErrorStateView(
          message: gym.meError,
          onRetry: () => gym.fetchAll(),
        ),
      );
    }

    final me = gym.me;
    if (me == null) {
      return const Scaffold(
        body: LoadingBlock(),
      );
    }

    final member = me.member;
    final membership = me.membership;
    final due = double.tryParse(me.outstandingInvoices) ?? 0.0;
    final dayKey = AppFormat.todayWeekday();
    final todayRoutine = gym.fitness?.workout?.routine?.days[dayKey];
    final activeServices = me.services.where((s) => s.status == 'active').toList();
    final today = AppFormat.todayKey();
    final visitedToday = gym.attendance?.visitDates.contains(today) ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => gym.fetchAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 16,
            16,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: identity + notifications
              _buildHeader(context, member, me),
              const SizedBox(height: 14),

              // Membership Hero Banner
              _buildMembershipHero(context, membership, visitedToday, me.activeFreeze),
              const SizedBox(height: 12),
              if (me.upcomingFreeze != null && me.activeFreeze == null) ...[
                UpcomingFreezeBanner(freeze: me.upcomingFreeze!, onTap: () => _openFreeze(context)),
                const SizedBox(height: 12),
              ],
              if (gym.memberOfTheMonth != null) ...[
                MemberOfTheMonthCard(
                  motm: gym.memberOfTheMonth!,
                  compact: true,
                ),
                const SizedBox(height: 12),
              ],
              for (final offer in gym.offers.where((o) => o.type == "renewal_bonus")) ...[
                _buildOfferBanner(context, offer),
                const SizedBox(height: 12),
              ],

              // Quick Access Grid
              const SectionHeader(title: 'Quick access', icon: Icons.bolt_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickTile(
                      icon: Icons.credit_card_outlined,
                      label: 'Billing',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BillingScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickTile(
                      icon: Icons.card_giftcard_outlined,
                      label: 'Refer & earn',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReferralsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickTile(
                      icon: Icons.ac_unit,
                      label: 'Freeze Plan',
                      onTap: () => _openFreeze(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Outstanding Invoices Alert
              if (due > 0) ...[
                AppCard(
                  backgroundColor: AppColors.warningSoft,
                  borderColor: const Color(0xFFF6DDAA),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BillingScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const IconBubble(
                        name: Icons.receipt_long_outlined,
                        color: AppColors.warning,
                        bg: Color(0xFFFFE6B8),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppFormat.money(due)} outstanding',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const Text(
                              'Tap to review your unpaid invoices.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Stat Tiles
              const SectionHeader(title: 'Check-ins', icon: Icons.event_available_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatTile(
                    icon: Icons.local_fire_department,
                    label: 'Day visit streak',
                    value: '${gym.attendance?.streak ?? 0}',
                    tint: const Color(0xFFE8590C),
                    bg: const Color(0xFFFFEDE0),
                  ),
                  const SizedBox(width: 10),
                  StatTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Visits this month',
                    value: '${gym.attendance?.thisMonth ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Workout Section
              if (gym.fitness?.workout != null) ...[
              SectionHeader(
                title: "Today's workout",
                icon: Icons.fitness_center,
                action: 'Open plan',
                onAction: onNavigateToTrain,
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: onNavigateToTrain,
                child: gym.fitness?.workout != null
                    ? (todayRoutine != null && !todayRoutine.isRestDay && todayRoutine.exercises.isNotEmpty)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const IconBubble(name: Icons.fitness_center),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          todayRoutine.label.isNotEmpty ? todayRoutine.label : gym.fitness!.workout!.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        Text(
                                          '${todayRoutine.exercises.length} exercises · ${gym.fitness!.workout!.name}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 4),
                              for (final e in todayRoutine.exercises.take(4).toList().asMap().entries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primarySoft,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e.value.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${e.value.sets} × ${e.value.reps}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (todayRoutine.exercises.length > 4)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+${todayRoutine.exercises.length - 4} more exercises',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const Row(
                            children: [
                              IconBubble(
                                name: Icons.coffee_outlined,
                                color: AppColors.success,
                                bg: AppColors.successSoft,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rest day',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    Text(
                                      'Recover well. Your next session is on the plan.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                    : const Row(
                        children: [
                          IconBubble(
                            name: Icons.assignment_outlined,
                            color: AppColors.textMuted,
                            bg: AppColors.surfaceAlt,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No plan assigned yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  'Ask your trainer to set up a workout plan for you.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              ],

              // Recent notifications
              if (gym.notifications.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recent notifications',
                  icon: Icons.notifications_none_rounded,
                  action: 'See all',
                  onAction: () => _openNotifications(context),
                ),
                const SizedBox(height: 12),
                for (final n in gym.notifications.take(3)) ...[
                  _buildRecentNotification(context, n),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
              ],

              // Active Add-on Services
              if (activeServices.isNotEmpty) ...[
                const SectionHeader(title: 'Add-on services', icon: Icons.add_circle_outline),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeServices.map((s) {
                    return AppBadge(
                      text: '${s.name} · till ${AppFormat.formatDate(s.endDate)}',
                      tone: BadgeTone.info,
                      icon: Icons.check_circle_outline,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Member member, MeResponse me) {
    final unread = me.unreadNotifications;
    final displayName = member.fullName.trim();

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Open profile, ${member.fullName}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onNavigateToProfile();
              },
              child: Row(
                children: [
                  AppAvatar(
                    name: member.fullName,
                    uri: member.photoUrl,
                    size: 52,
                    ring: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormat.greeting(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Member ID chip: a quiet identity detail, not a second headline.
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.badge_outlined, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  member.registrationNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDeep.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: AppColors.text,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.bg, width: 2),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferBanner(BuildContext context, Offer offer) {
    final badge = offer.daysLeft <= 1 ? 'Last day!' : '${offer.daysLeft}d left';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onNavigateToOffers,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8590C), Color(0xFFF59F00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to see details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.95)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCheckIn() {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Checked in at the gym today',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipHero(BuildContext context, MembershipView? m, bool visitedToday, FreezeRequest? activeFreeze) {
    if (m == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NO MEMBERSHIP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: Color(0xBFFFFFFF),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Join a plan to get started',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Visit the front desk or browse the plans available.',
              style: TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
            ),
            const SizedBox(height: 16),
            AppButton(
              title: 'View plans',
              variant: ButtonVariant.light,
              small: true,
              onPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MembershipScreen()),
                );
              },
            ),
          ],
        ),
      );
    }

    final isFrozen = m.status == 'frozen';
    final isExpired = m.status == 'expired' || (m.daysLeft < 0 && !isFrozen);
    final isExpiring = !isExpired && !isFrozen && m.daysLeft <= 7;

    List<Color> gradientColors = isFrozen
        ? [const Color(0xFF0B4F6C), const Color(0xFF0E7490), const Color(0xFF22A6C8)]
        : isExpired
        ? [const Color(0xFF5B1A1A), const Color(0xFF8E2B2B), const Color(0xFFB53A3A)]
        : isExpiring
            ? [const Color(0xFF7A4A00), const Color(0xFFB26B00), const Color(0xFFD98A00)]
            : [AppColors.primaryDeep, AppColors.primaryDark, AppColors.primary];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MembershipScreen()),
        );
      },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.package.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Color(0xBFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFrozen
                          ? 'Membership Frozen'
                          : isExpired
                          ? 'Membership expired'
                          : m.daysLeft == 0
                              ? 'Expires today'
                              : '${m.daysLeft} day${m.daysLeft == 1 ? '' : 's'} left',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isExpired ? 'Expired' : (isFrozen ? 'Frozen' : AppFormat.titleCase(m.status)),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (isFrozen) ...[
            const SizedBox(height: 4),
            Text(
              'Paused till ${AppFormat.formatDate(activeFreeze?.endDate)} · Expiry extended to ${AppFormat.formatDate(m.endDate)}',
              style: const TextStyle(fontSize: 12, color: Color(0xE6FFFFFF)),
            ),
          ],
          const SizedBox(height: 10),
          AppProgressBar(
            value: isExpired ? 1.0 : m.progress,
            color: Colors.white,
            track: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppFormat.formatDate(m.startDate),
                style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
              ),
              Text(
                '${isExpired ? "Ended" : "Valid till"} ${AppFormat.formatDate(m.endDate)}',
                style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
              ),
            ],
          ),
          if (visitedToday) ...[
            const SizedBox(height: 8),
            _buildTodayCheckIn(),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isExpired || isExpiring ? 'Tap to renew' : 'Tap to see details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.85)),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBubble(name: icon, size: 36),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

}
