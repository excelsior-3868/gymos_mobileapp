import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/gym_provider.dart';
import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GymProvider>(context, listen: false).fetchAll();
    });
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
            _buildNavItem(1, Icons.fitness_center_outlined, Icons.fitness_center, 'Train'),
            _buildNavItem(2, Icons.local_offer_outlined, Icons.local_offer, 'Offers'),
            _buildNavItem(3, Icons.timeline_outlined, Icons.timeline, 'Activity'),
            _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData idleIcon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      flex: isSelected ? 3 : 2,
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
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 14 : 10),
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
