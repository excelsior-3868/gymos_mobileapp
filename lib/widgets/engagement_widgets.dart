import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/config.dart';
import '../utils/format.dart';
import 'ui_components.dart';

const Color kIndigo = Color(0xFF4F46E5);
const Color kIndigoSoft = Color(0xFFE8E7FD);
const Color kGold = Color(0xFFB7791F);
const Color kGoldSoft = Color(0xFFFFF4D6);
const Color kFreeze = Color(0xFF0891B2);
const Color kFreezeSoft = Color(0xFFE0F5FA);

/// Visual identity for a notice category.
({IconData icon, Color color, Color bg, String label}) noticeCategoryStyle(String category) {
  switch (category) {
    case 'event':
      return (icon: Icons.event_outlined, color: kIndigo, bg: kIndigoSoft, label: 'Upcoming Event');
    case 'urgent':
      return (icon: Icons.priority_high_rounded, color: AppColors.danger, bg: AppColors.dangerSoft, label: 'Urgent');
    case 'holiday':
      return (icon: Icons.celebration_outlined, color: AppColors.success, bg: AppColors.successSoft, label: 'Holiday');
    default:
      return (icon: Icons.campaign_outlined, color: AppColors.info, bg: AppColors.infoSoft, label: 'Notice');
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color fg;
  final Color bg;

  const _Chip({required this.text, this.icon, this.fg = Colors.white, this.bg = const Color(0x33FFFFFF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// FitMaxim Member of the Month. [compact] renders the small Home banner.
class MemberOfTheMonthCard extends StatelessWidget {
  final MemberOfTheMonth motm;
  final bool compact;
  final VoidCallback? onTap;

  const MemberOfTheMonthCard({super.key, required this.motm, this.compact = false, this.onTap});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF3B2A06), Color(0xFF8A5A0B), Color(0xFFD99A1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final kicker = '${motm.title} · ${motm.monthLabel}'.toUpperCase();
    final w = motm.winner;
    final hasPhoto = AppConfig.mediaUrl(w.photoUrl) != null;

    final content = compact
        ? Row(
            children: [
              if (hasPhoto) ...[
                AppAvatar(name: w.fullName, uri: w.photoUrl, size: 48, ring: true),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 ${motm.title} · ${motm.monthLabel}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Color(0xDDFFFFFF)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      motm.isCurrentMember ? "That's you! 🎉" : w.fullName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    if (motm.giftHamper.isNotEmpty)
                      Text(
                        '🎁 ${motm.giftHamper}',
                        style: const TextStyle(fontSize: 12, color: Color(0xDDFFFFFF)),
                      ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '🏆 $kicker',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xDDFFFFFF)),
              ),
              const SizedBox(height: 14),
              if (hasPhoto) ...[
                Center(child: AppAvatar(name: w.fullName, uri: w.photoUrl, size: 84, ring: true)),
                const SizedBox(height: 10),
              ],
              Text(
                w.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                w.registrationNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
              ),
              if (motm.isCurrentMember) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: const Text(
                    "🎉 That's You! Claim your Gift Hamper at reception.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGold),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (motm.giftHamper.isNotEmpty) _Chip(text: '🎁 ${motm.giftHamper}'),
                  _Chip(text: '${motm.attendanceDays} visits', icon: Icons.directions_walk),
                  if (motm.onTimeRenewal) const _Chip(text: 'On-time renewal', icon: Icons.verified_outlined),
                  if (motm.referralCount > 0) _Chip(text: '${motm.referralCount} referrals', icon: Icons.group_add_outlined),
                ],
              ),
              if (motm.message != null && motm.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  motm.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xE6FFFFFF)),
                ),
              ],
            ],
          );

    final card = Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: content,
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      child: card,
    );
  }
}

/// Single notice/event card. [preview] shows a compact 2-line version.
class NoticeCard extends StatelessWidget {
  final NoticeItem notice;
  final bool preview;
  final VoidCallback? onTap;

  const NoticeCard({super.key, required this.notice, this.preview = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = noticeCategoryStyle(notice.category);
    final hasDate = notice.eventDate != null && notice.eventDate!.isNotEmpty;
    final hasTime = notice.eventTime != null && notice.eventTime!.isNotEmpty;
    final hasLoc = notice.location != null && notice.location!.isNotEmpty;

    Widget meta(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Flexible(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          ],
        );

    return AppCard(
      onTap: onTap,
      borderColor: notice.isPinned ? s.color : AppColors.border,
      borderWidth: notice.isPinned ? 1.6 : 1.0,
      padding: EdgeInsets.all(preview ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(name: s.icon, color: s.color, bg: s.bg, size: preview ? 36 : 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!preview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(text: s.label, fg: s.color, bg: s.bg),
                        if (notice.isPinned) const _Chip(text: 'Pinned', icon: Icons.push_pin_outlined, fg: kGold, bg: kGoldSoft),
                        if (hasDate) _Chip(text: AppFormat.formatDateShort(notice.eventDate), icon: Icons.event, fg: kIndigo, bg: kIndigoSoft),
                      ],
                    ),
                  ),
                Text(
                  notice.title,
                  
                  
                  style: TextStyle(fontSize: preview ? 14 : 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 3),
                // Always plain Text: notice content is never parsed as HTML.
                Text(
                  notice.content,
                  
                  
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
                ),
                if (hasDate || hasTime || hasLoc) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (hasDate) meta(Icons.calendar_today_outlined, AppFormat.formatDate(notice.eventDate)),
                      if (hasTime) meta(Icons.schedule, notice.eventTime!),
                      if (hasLoc) meta(Icons.place_outlined, notice.location!),
                    ],
                  ),
                ],
                if (!preview && notice.createdAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(AppFormat.timeAgo(notice.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet shown once per login session: Member of the Month + top notices.
class LoginSpotlight extends StatelessWidget {
  final NoticeboardResponse data;
  final VoidCallback onViewNotifications;

  const LoginSpotlight({super.key, required this.data, required this.onViewNotifications});

  static Future<void> show(
    BuildContext context, {
    required NoticeboardResponse data,
    required VoidCallback onViewNotifications,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => LoginSpotlight(data: data, onViewNotifications: onViewNotifications),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motm = data.memberOfTheMonth;
    // Pinned first, then events/notices in server order; top 3.
    final items = [...data.notices]..sort((a, b) => (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0));
    final top = items.take(3).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                if (motm != null) ...[
                  MemberOfTheMonthCard(motm: motm),
                  const SizedBox(height: 16),
                ],
                if (top.isNotEmpty) ...[
                  const SectionHeader(title: 'Noticeboard', icon: Icons.campaign_outlined),
                  const SizedBox(height: 10),
                  for (final n in top) ...[
                    NoticeCard(notice: n, preview: true),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: 'View Notifications',
                    variant: ButtonVariant.secondary,
                    onPress: () {
                      Navigator.pop(context);
                      onViewNotifications();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: AppButton(title: 'Got it', onPress: () => Navigator.pop(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Info banner: "Freeze scheduled (N days): start → end".
class UpcomingFreezeBanner extends StatelessWidget {
  final FreezeRequest freeze;
  final VoidCallback onTap;

  const UpcomingFreezeBanner({super.key, required this.freeze, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: kFreezeSoft,
      borderColor: const Color(0xFFB5E4EE),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const IconBubble(name: Icons.ac_unit, color: kFreeze, bg: Colors.white, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Freeze scheduled (${freeze.freezeDays} days): '
              '${AppFormat.formatDate(freeze.startDate)} → ${AppFormat.formatDate(freeze.endDate)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
            ),
          ),
          const Icon(Icons.chevron_right, color: kFreeze),
        ],
      ),
    );
  }
}
