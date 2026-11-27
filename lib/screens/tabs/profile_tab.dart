import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/biometric_setup_sheet.dart';
import '../../widgets/ui_components.dart';
import '../change_password_screen.dart';
import '../sub_screens/billing_screen.dart';
import '../sub_screens/edit_profile_screen.dart';
import '../sub_screens/membership_screen.dart';
import '../sub_screens/notifications_screen.dart';
import '../sub_screens/pass_screen.dart';
import '../sub_screens/referrals_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _confirmLogout(BuildContext context, String gymName) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          auth.canLoginWithBiometrics
              ? 'You can sign back in with ${auth.biometricLabel} or your password.'
              : 'You will need your username and password to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final gym = Provider.of<GymProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      gym.clearData();
      await auth.signOut();
    }
  }

  Future<void> _changePhoto(BuildContext context, bool hasPhoto) async {
    final gym = Provider.of<GymProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    try {
      if (choice == 'remove') {
        await gym.removeProfilePhoto();
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile photo removed.')),
        );
        return;
      }
      final picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final lower = picked.path.toLowerCase();
      await gym.uploadProfilePhoto(
        picked.path,
        mime: lower.endsWith('.png') ? 'image/png' : 'image/jpeg',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final brand = Provider.of<BrandingProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (gym.isLoadingMe && gym.me == null) {
      return const Scaffold(body: LoadingBlock());
    }

    if (gym.meError != null && gym.me == null) {
      return Scaffold(
        body: ErrorStateView(
          message: gym.meError,
          onRetry: () => gym.fetchMe(),
        ),
      );
    }

    final me = gym.me;
    if (me == null) return const Scaffold(body: LoadingBlock());

    final member = me.member;
    final due = double.tryParse(me.outstandingInvoices) ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => gym.fetchMe(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            topPadding + 16,
            16,
            bottomPadding + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenTitle(
                title: 'Profile',
                subtitle: 'Your account and settings',
              ),
              const SizedBox(height: 16),

              // Profile Header Card
              AppCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _changePhoto(
                        context,
                        (member.photoUrl ?? '').isNotEmpty,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppAvatar(
                            name: member.fullName,
                            uri: member.photoUrl,
                            size: 96,
                            ring: true,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.photo_camera,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      member.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppBadge(
                          text: 'ID ${member.registrationNumber}',
                          tone: BadgeTone.info,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(width: 8),
                        AppBadge(
                          text: member.isActive == true ? 'Active' : 'Inactive',
                          tone: member.isActive == true
                              ? BadgeTone.success
                              : BadgeTone.danger,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Member since ${AppFormat.formatDate(member.registrationDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Menu Card
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _buildRow(
                      icon: Icons.qr_code_2_rounded,
                      title: 'Gym pass',
                      subtitle: 'Show your QR code at the gate',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PassScreen()),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.card_membership_outlined,
                      title: 'My membership',
                      subtitle: 'Plan, validity and history',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MembershipScreen(),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.credit_card_outlined,
                      title: 'Billing & payments',
                      subtitle: due > 0
                          ? '${AppFormat.money(due)} outstanding'
                          : 'Invoices and receipts',
                      right: due > 0
                          ? const AppBadge(text: 'Due', tone: BadgeTone.warning)
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BillingScreen(),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      right: me.unreadNotifications > 0
                          ? AppBadge(
                              text: '${me.unreadNotifications} new',
                              tone: BadgeTone.info,
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.emoji_events_outlined,
                      title: 'Employee of the Month',
                      subtitle: 'Current winner & award history',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(initialTab: 1),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.card_giftcard_outlined,
                      title: 'Refer & earn',
                      subtitle: 'Invite friends, earn rewards',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReferralsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Personal Details Card
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _buildRow(
                      icon: Icons.person_outline,
                      title: 'Personal details',
                      subtitle: member.email ?? 'Add your email',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.water_drop_outlined,
                      title: 'Blood group',
                      right: Text(
                        member.bloodGroup ?? '—',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      hasChevron: false,
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.flag_outlined,
                      title: 'Fitness goal',
                      subtitle: member.fitnessGoals ?? 'Not set',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: Icons.lock_outline,
                      title: 'Change password',
                      subtitle: 'Update your login password',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ChangePasswordScreen(isForced: false),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildRow(
                      icon: auth.biometricLabel.toLowerCase().contains('face')
                          ? Icons.face_rounded
                          : Icons.fingerprint_rounded,
                      title: '${auth.biometricLabel} login',
                      subtitle: auth.biometricAvailable
                          ? (auth.biometricEnabled
                                ? 'Enabled for quick sign-in'
                                : 'Use ${auth.biometricLabel} to sign in')
                          : auth.biometricSupported
                          ? 'Enroll fingerprint/Face ID in device settings first'
                          : 'Not available on this device',
                      hasChevron: false,
                      onTap: auth.biometricAvailable
                          ? null
                          : () async {
                              await auth.refreshBiometricStatus();
                              if (!context.mounted) return;
                              if (auth.biometricAvailable) {
                                await BiometricSetupSheet.show(
                                  context,
                                  username: member.registrationNumber,
                                  requirePassword: true,
                                );
                              } else {
                                await showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                    ),
                                    title: Text(
                                      auth.biometricSupported
                                          ? 'Biometrics not set up'
                                          : 'Biometrics unavailable',
                                    ),
                                    content: Text(
                                      auth.biometricSupported
                                          ? 'No biometrics enrolled yet. Add a Fingerprint or Face ID in your device Settings first.'
                                          : 'Biometric authentication is not supported on this device.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                        ),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                      right: Switch.adaptive(
                        value: auth.biometricAvailable && auth.biometricEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: !auth.biometricAvailable
                            ? null
                            : (enabled) async {
                                HapticFeedback.selectionClick();
                                if (enabled) {
                                  await BiometricSetupSheet.show(
                                    context,
                                    username: member.registrationNumber,
                                    requirePassword: true,
                                  );
                                } else {
                                  await auth.disableBiometric();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${auth.biometricLabel} login disabled.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              AppButton(
                title: 'Log out',
                icon: Icons.logout_outlined,
                variant: ButtonVariant.danger,
                onPress: () => _confirmLogout(context, brand.gymName),
              ),
              const SizedBox(height: 16),
              Text(
                '${brand.gymName} Member · v1.0.0',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? right,
    VoidCallback? onTap,
    bool hasChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconBubble(name: icon, size: 38),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (right != null) ...[right, const SizedBox(width: 8)],
              if (hasChevron && onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
