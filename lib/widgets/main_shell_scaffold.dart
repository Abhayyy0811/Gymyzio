import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/fitgine_ai_floating_button.dart';
import '../theme/app_theme.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state_providers.dart';

class MainShellScaffold extends ConsumerWidget {
  final Widget child;

  const MainShellScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/badges')) return 3;
    if (location.startsWith('/dietchamp')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/library');
        break;
      case 2:
        context.go('/progress');
        break;
      case 3:
        context.go('/badges');
        break;
      case 4:
        context.go('/dietchamp');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  Color _getTabAccentColor(int index) {
    return AppColors.primary; // Royal Blue glow & accent for all navbar tabs
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(userProfileProvider);

    // Strict Guard: Redirect incomplete profiles away from main shell to /onboarding
    if (currentUser != null && !profile.isFullyCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/onboarding');
        }
      });
    }

    final selectedIndex = _calculateSelectedIndex(context);
    final tr = ref.watch(trProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    if (isDesktop) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradientOf(context),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              // Left Desktop Navigation Sidebar
              Container(
                width: 240,
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  border: Border(
                    right: BorderSide(color: AppColors.borderOf(context), width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gymyzio Desktop Branding Header
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36 * 0.22),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.all(36 * 0.12),
                                child: Image.asset(
                                  'assets/icon/app_icon_avatar.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.fitness_center_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Gymyzio',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryOf(context),
                                fontFamily: 'Outfit',
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Sidebar Navigation List
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: [
                            _buildSidebarItem(context, index: 0, icon: Icons.grid_view_rounded, label: tr('nav_home'), isSelected: selectedIndex == 0),
                            const SizedBox(height: 6),
                            _buildSidebarItem(context, index: 1, icon: Icons.fitness_center_rounded, label: tr('nav_library'), isSelected: selectedIndex == 1),
                            const SizedBox(height: 6),
                            _buildSidebarItem(context, index: 2, icon: Icons.show_chart_rounded, label: tr('nav_progress'), isSelected: selectedIndex == 2),
                            const SizedBox(height: 6),
                            _buildSidebarItem(context, index: 3, icon: Icons.military_tech_rounded, label: tr('nav_badges'), isSelected: selectedIndex == 3),
                            const SizedBox(height: 6),
                            _buildSidebarItem(context, index: 4, icon: Icons.restaurant_menu_rounded, label: tr('nav_dietchamp'), isSelected: selectedIndex == 4),
                            const SizedBox(height: 6),
                            _buildSidebarItem(context, index: 5, icon: Icons.tune_rounded, label: tr('nav_settings'), isSelected: selectedIndex == 5),
                          ],
                        ),
                      ),

                      // Desktop Version Branding Footer
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Gymyzio Web v1.0.0',
                          style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Desktop Page Content Container
              Expanded(
                child: Stack(
                  children: [
                    child,
                    const FitGineAIFloatingButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradientOf(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            child,
            const FitGineAIFloatingButton(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0, top: 4.0),
            child: Center(
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.borderOf(context),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(context, index: 0, icon: Icons.grid_view_rounded, label: tr('nav_home'), isSelected: selectedIndex == 0),
                      _buildNavItem(context, index: 1, icon: Icons.fitness_center_rounded, label: tr('nav_library'), isSelected: selectedIndex == 1),
                      _buildNavItem(context, index: 2, icon: Icons.show_chart_rounded, label: tr('nav_progress'), isSelected: selectedIndex == 2),
                      _buildNavItem(context, index: 3, icon: Icons.military_tech_rounded, label: tr('nav_badges'), isSelected: selectedIndex == 3),
                      _buildNavItem(context, index: 4, icon: Icons.restaurant_menu_rounded, label: tr('nav_dietchamp'), isSelected: selectedIndex == 4),
                      _buildNavItem(context, index: 5, icon: Icons.tune_rounded, label: tr('nav_settings'), isSelected: selectedIndex == 5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final activeColor = _getTabAccentColor(index);
    final inactiveColor = AppColors.textSecondaryOf(context);

    return AppBouncyTap(
      onTap: () => _onItemTapped(index, context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : AppColors.textPrimaryOf(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.softGlow(activeColor, opacity: 0.6, blur: 4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final activeColor = _getTabAccentColor(index);
    final inactiveColor = AppColors.textSecondary; // High contrast dark slate for inactive tabs

    return AppBouncyTap(
      onTap: () => _onItemTapped(index, context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Outfit',
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
