import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/engagement_widgets.dart';
import '../../widgets/ui_components.dart';
import 'freeze_request_screen.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  String _cycleLabel(int days, String cycle) {
    if (cycle.isNotEmpty && cycle != 'custom') {
      return AppFormat.titleCase(cycle);
    }
    if (days % 30 == 0) {
      final months = days ~/ 30;
      return '$months month${months == 1 ? "" : "s"}';
    }
    return '$days days';
  }

  void _openFreeze(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FreezeRequestScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final current = gym.me?.membership;
    final isFrozen = current?.status == 'frozen';
    final isExpired = current == null || current.status == 'expired' || (current.daysLeft < 0 && !isFrozen);
    final activeFreeze = gym.me?.activeFreeze;
    final upcomingFreeze = gym.me?.upcomingFreeze;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            gym.fetchMe(),
            gym.fetchPackages(),
            gym.fetchMembershipHistory(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: 'My membership',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),

              if (upcomingFreeze != null && activeFreeze == null) ...[
                UpcomingFreezeBanner(freeze: upcomingFreeze, onTap: () => _openFreeze(context)),
                const SizedBox(height: 12),
              ],

              // Current Membership Card
              if (current != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const IconBubble(name: Icons.military_tech_outlined, size: 48),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.package.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${_cycleLabel(current.package.durationDays, current.package.billingCycle)} plan',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppBadge(
                                text: isExpired ? 'Expired' : (isFrozen ? 'Frozen' : AppFormat.titleCase(current.status)),
                                tone: isExpired ? BadgeTone.danger : getStatusTone(current.status),
                                icon: isFrozen ? Icons.ac_unit : null,
                              ),
                              if (!isExpired) ...[
                                const SizedBox(height: 4),
                                Text(
                                  current.daysLeft == 0
                                      ? 'Expires today'
                                      : '${current.daysLeft} day${current.daysLeft == 1 ? '' : 's'} left',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Progress Bar
                      AppProgressBar(
                        value: isExpired ? 1.0 : current.progress,
                        color: isExpired
                            ? AppColors.danger
                            : current.daysLeft <= 7
                                ? AppColors.warning
                                : AppColors.primary,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppFormat.formatDate(current.startDate),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          Text(
                            AppFormat.formatDate(current.endDate),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),

                      // Optional Facts Grid (Sessions / Hours)
                      if (current.totalSessions != null ||
                          (current.package.startTime != null && current.package.endTime != null)) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (current.totalSessions != null)
                              _buildFactTile('Sessions', '${current.usedSessions ?? 0}/${current.totalSessions}'),
                            if (current.package.startTime != null && current.package.endTime != null)
                              _buildFactTile('Hours', '${current.package.startTime}–${current.package.endTime}'),
                          ],
                        ),
                      ],

                      if (current.package.includedServices.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: current.package.includedServices.map((s) {
                            return AppBadge(
                              text: s,
                              tone: BadgeTone.info,
                              icon: Icons.check,
                            );
                          }).toList(),
                        ),
                      ],

                      if (isFrozen) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kFreezeSoft,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.ac_unit, size: 20, color: kFreeze),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Membership Frozen',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                                    ),
                                    Text(
                                      'Paused till ${AppFormat.formatDate(activeFreeze?.endDate)} · Expiry extended to ${AppFormat.formatDate(current.endDate)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (canRequestFreeze(current)) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          title: isFrozen ? 'View Freeze Details' : 'Request Membership Freeze',
                          icon: Icons.ac_unit,
                          variant: ButtonVariant.secondary,
                          onPress: () => _openFreeze(context),
                        ),
                      ],

                      if (isExpired) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: AppColors.warning),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your plan has ended. Renew at the front desk or pay via eSewa/Khalti.',
                                  style: TextStyle(fontSize: 12, color: AppColors.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.card_membership_outlined,
                    title: 'No membership yet',
                    message: 'Pick a plan below and complete registration at the front desk.',
                  ),
                ),
              const SizedBox(height: 24),

              // Add-on Services
              if (gym.me?.services.isNotEmpty == true) ...[
                const SectionHeader(title: 'Add-on services'),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: gym.me!.services.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: i > 0
                              ? const Border(top: BorderSide(color: AppColors.border, width: 0.8))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${AppFormat.formatDate(s.startDate)} → ${AppFormat.formatDate(s.endDate)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            AppBadge(
                              text: AppFormat.titleCase(s.status),
                              tone: getStatusTone(s.status),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Available Plans
              const SectionHeader(title: 'Available plans'),
              const SizedBox(height: 12),
              if (gym.isLoadingPackages && gym.packages.isEmpty)
                const LoadingBlock()
              else
                ...gym.packages.map((p) {
                  final isMine = current?.package.id == p.id && !isExpired;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      borderColor: isMine ? AppColors.primary : AppColors.border,
                      borderWidth: isMine ? 1.8 : 1.0,
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
                                      p.name,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '${_cycleLabel(p.durationDays, p.billingCycle)}${p.sessionCount != null ? " · ${p.sessionCount} sessions" : ""}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppFormat.money(p.price),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (p.description != null && p.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              p.description!,
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                          if (p.includedServices.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: p.includedServices.map((s) {
                                return AppBadge(text: s, tone: BadgeTone.neutral);
                              }).toList(),
                            ),
                          ],
                          if (isMine) ...[
                            const SizedBox(height: 12),
                            const AppBadge(
                              text: 'Your current plan',
                              tone: BadgeTone.success,
                              icon: Icons.check_circle_outline,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Renewals and payments are completed at the front desk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),

              // Membership History
              if (gym.membershipHistory.length > 1) ...[
                const SizedBox(height: 16),
                const SectionHeader(title: 'History'),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: gym.membershipHistory.asMap().entries.map((entry) {
                      final i = entry.key;
                      final h = entry.value;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: i > 0
                              ? const Border(top: BorderSide(color: AppColors.border, width: 0.8))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.package.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${AppFormat.formatDate(h.startDate)} → ${AppFormat.formatDate(h.endDate)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            AppBadge(
                              text: h.daysLeft < 0 && h.status == 'active' ? 'Expired' : AppFormat.titleCase(h.status),
                              tone: h.daysLeft < 0 ? BadgeTone.neutral : getStatusTone(h.status),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
