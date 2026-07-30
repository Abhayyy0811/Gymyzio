import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_settings_provider.dart';

class MainShellScaffold extends ConsumerWidget {
  final Widget child;

  const MainShellScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/badges')) return 3;
    if (location.startsWith('/settings')) return 4;
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
        context.go('/settings');
        break;
    }
  }

  Color _getTabAccentColor(int index) {
    switch (index) {
      case 0:
        return AppColors.homeAccent;
      case 1:
        return AppColors.libraryAccent;
      case 2:
        return AppColors.progressAccent;
      case 3:
        return AppColors.badgesAccent;
      case 4:
        return AppColors.settingsAccent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final tr = ref.watch(trProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: child,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0, top: 4.0),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.border,
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
                  _buildNavItem(context, index: 4, icon: Icons.tune_rounded, label: tr('nav_settings'), isSelected: selectedIndex == 4),
                ],
              ),
            ),
          ),
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
