import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/biometric_setup_sheet.dart';
import 'sub_screens/notifications_screen.dart';
import 'tabs/activity_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/offers_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/train_tab.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _checkedBiometricPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gym = Provider.of<GymProvider>(context, listen: false);
      gym.fetchAll();
      _maybePromptBiometricSetup();

      PushNotificationService.onForegroundMessage = () {
        if (!mounted) return;
        gym.fetchNotifications();
        gym.fetchMe();
      };
      PushNotificationService.onNotificationTapped = () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      };
      PushNotificationService.consumePendingTap();
    });
  }

  @override
  void dispose() {
    PushNotificationService.onForegroundMessage = null;
    PushNotificationService.onNotificationTapped = null;
    super.dispose();
  }

  Future<void> _maybePromptBiometricSetup() async {
    if (_checkedBiometricPrompt || !mounted) return;
    _checkedBiometricPrompt = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.refreshBiometricStatus();
    if (!mounted || !auth.shouldPromptBiometricSetup) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !auth.shouldPromptBiometricSetup) return;

    final gym = Provider.of<GymProvider>(context, listen: false);
    final username = auth.savedRegistrationNumber ?? gym.me?.member.registrationNumber;

    await BiometricSetupSheet.show(
      context,
      username: username,
      isFirstTimePrompt: true,
    );
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final screens = [
      HomeTab(
        onNavigateToTrain: () => _onTabSelected(1),
        onNavigateToOffers: () => _onTabSelected(2),
        onNavigateToProfile: () => _onTabSelected(4),
      ),
      const TrainTab(),
      const OffersTab(),
      const ActivityTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8, top: 8, left: 8, right: 8),
        child: Row(
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(1, Icons.fitness_center_outlined, Icons.fitness_center, 'Train & Diet'),
            _buildNavItem(2, Icons.local_offer_outlined, Icons.local_offer, 'Offers'),
            _buildNavItem(3, Icons.event_available_outlined, Icons.event_available, 'Check-ins'),
            _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData idleIcon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      flex: isSelected ? (label.length > 8 ? 5 : 3) : 2,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTabSelected(index),
          child: Center(
            heightFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? activeIcon : idleIcon,
                    size: 24,
                    color: isSelected ? Colors.white : AppColors.textFaint,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
