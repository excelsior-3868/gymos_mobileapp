import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui_components.dart';

class ReferralsScreen extends StatelessWidget {
  const ReferralsScreen({super.key});

  void _shareReferral(String referralCode) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Join me at the gym! When you register, tell them my member ID $referralCode so we both get rewarded. 💪',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (gym.isLoadingReferrals && gym.referrals == null) {
      return const Scaffold(body: LoadingBlock());
    }

    if (gym.referralsError != null && gym.referrals == null) {
      return Scaffold(
        body: ErrorStateView(
          message: gym.referralsError,
          onRetry: () => gym.fetchReferrals(),
        ),
      );
    }

    final data = gym.referrals;
    if (data == null) {
      return const Scaffold(body: LoadingBlock());
    }

    final remaining = data.milestone - data.towardsNextReward;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => gym.fetchReferrals(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: 'Refer & earn',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),

              // Referral Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDeep, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR REFERRAL ID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.referralCode,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Friends who join using your ID count toward a reward. Every ${data.milestone} successful referrals earns you a membership extension.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xDDFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      title: 'Invite a friend',
                      icon: Icons.share_outlined,
                      variant: ButtonVariant.light,
                      small: true,
                      onPress: () => _shareReferral(data.referralCode),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progress Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress to next reward',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${data.towardsNextReward}/${data.milestone}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppProgressBar(
                      value: data.milestone > 0 ? data.towardsNextReward / data.milestone : 0,
                      height: 10,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      remaining > 0
                          ? '$remaining more successful referral${remaining == 1 ? "" : "s"} to unlock your reward.'
                          : 'Reward unlocked! Ask the front desk to redeem it.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reward Codes
              if (data.rewardCodes.isNotEmpty) ...[
                const SectionHeader(title: 'Your reward codes'),
                const SizedBox(height: 12),
                ...data.rewardCodes.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        backgroundColor: AppColors.successSoft,
                        borderColor: const Color(0xFFBFE8CF),
                        child: Row(
                          children: [
                            IconBubble(
                              name: Icons.card_giftcard,
                              color: AppColors.success,
                              bg: Colors.white.withOpacity(0.6),
                              size: 44,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.code,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 4,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const Text(
                                    'Show this code at the front desk when renewing.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
              ],

              // Referred Friends
              SectionHeader(title: 'Friends you referred (${data.total})'),
              const SizedBox(height: 12),
              if (data.referred.isEmpty)
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.people_outline,
                    title: 'No referrals yet',
                    message: 'Share your ID with friends to get started.',
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: data.referred.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;

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
                                    r.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    AppFormat.formatDate(r.createdAt),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            AppBadge(
                              text: AppFormat.titleCase(r.status),
                              tone: getStatusTone(r.status),
                            ),
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
