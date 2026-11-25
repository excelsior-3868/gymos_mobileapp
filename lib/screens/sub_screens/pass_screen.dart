import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/branding_provider.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui_components.dart';

class PassScreen extends StatelessWidget {
  const PassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final brand = Provider.of<BrandingProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final member = gym.me?.member;
    final membership = gym.me?.membership;
    final isValid = membership != null &&
        membership.status == 'active' &&
        membership.daysLeft >= 0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDeep, AppColors.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, bottomPadding + 20),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${brand.gymName} pass',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                  ),
                ),
              ],
            ),

            // Center Card
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: member != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppAvatar(
                                    name: member.fullName,
                                    uri: member.photoUrl,
                                    size: 68,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    member.fullName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID ${member.registrationNumber}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AppBadge(
                                    text: isValid
                                        ? 'Valid membership'
                                        : membership != null
                                            ? 'Membership expired'
                                            : 'No active plan',
                                    tone: isValid ? BadgeTone.success : BadgeTone.danger,
                                    icon: isValid ? Icons.check_circle_outline : Icons.error_outline,
                                  ),
                                  const SizedBox(height: 24),

                                  // QR Code
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: QrImageView(
                                      data: member.registrationNumber,
                                      version: QrVersions.auto,
                                      size: 190.0,
                                      backgroundColor: Colors.white,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: AppColors.text,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    membership != null
                                        ? '${membership.package.name} · ${isValid ? "valid till" : "ended"} ${AppFormat.formatDate(membership.endDate)}'
                                        : 'Visit the front desk to join a plan',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : const LoadingBlock(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Show this code at the front desk if the gate doesn't recognise your fingerprint.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
