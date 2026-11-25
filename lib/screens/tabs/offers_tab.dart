import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_components.dart';

class OffersTab extends StatelessWidget {
  const OffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final offers = gym.offers;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => gym.fetchOffers(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 16,
            16,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            const ScreenTitle(
              title: 'Offers',
              subtitle: 'Special deals for members',
            ),
            const SizedBox(height: 16),
            if (offers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: EmptyStateView(
                  icon: Icons.local_offer_outlined,
                  title: 'No offers right now',
                  message: 'Check back soon for new membership offers.',
                ),
              )
            else
              for (final offer in offers) ...[
                _OfferCard(offer: offer),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  final Offer offer;
  const _OfferCard({required this.offer});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final badge = offer.daysLeft <= 1
        ? 'Last day!'
        : '${offer.daysLeft} days left';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8590C), Color(0xFFF59F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (offer.description != null &&
                    offer.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    offer.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Valid ${offer.startDate} to ${offer.endDate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Tap to hide details'
                          : 'Tap to see bonus days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'Bonus days on renewal'),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: offer.bonuses.asMap().entries.map((entry) {
                          final b = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: entry.key == 0
                                  ? null
                                  : const Border(
                                      top: BorderSide(color: AppColors.border),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${b.cycleLabel} plan',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                                AppBadge(
                                  text: '+${b.bonusDays} days free',
                                  tone: BadgeTone.success,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!offer.eligible)
                      const Text(
                        'This offer applies to membership renewals. Visit the front desk to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
