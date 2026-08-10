import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../l10n/app_strings.dart';
import '../utils/unit_converter.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier([ThemeMode? initialMode]) : super(initialMode ?? ThemeMode.light) {
    if (initialMode == null) {
      _loadThemeMode();
    }
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? modeStr = prefs.getString('app_theme_mode');
      if (modeStr == 'dark') {
        state = ThemeMode.dark;
        AppColors.currentThemeMode = ThemeMode.dark;
      } else {
        // Default light — also covers null (not yet saved) and 'light'
        state = ThemeMode.light;
        AppColors.currentThemeMode = ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    AppColors.currentThemeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String modeStr = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      await prefs.setString('app_theme_mode', modeStr);
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Returns the current language string ("English" or "हिंदी")
final appLanguageProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.language;
});

/// Returns the current unit system string ("Metric" or "Imperial")
final appUnitSystemProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.unitSystem;
});

/// Helper provider that returns a string lookup function `tr(key)` based on current language
final trProvider = Provider<String Function(String key)>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return (String key) => AppStrings.get(key, lang);
});

/// Helper provider for formatting weights dynamically according to unit system
final weightFormatterProvider = Provider<String Function(double weightKg, {int decimals, bool includeUnit})>((ref) {
  final unitSystem = ref.watch(appUnitSystemProvider);
  return (double weightKg, {int decimals = 1, bool includeUnit = true}) {
    return UnitConverter.formatWeight(weightKg, unitSystem, decimals: decimals, includeUnit: includeUnit);
  };
});

/// Helper provider for formatting heights dynamically according to unit system
final heightFormatterProvider = Provider<String Function(double heightCm, {bool includeUnit})>((ref) {
  final unitSystem = ref.watch(appUnitSystemProvider);
  return (double heightCm, {bool includeUnit = true}) {
    return UnitConverter.formatHeight(heightCm, unitSystem, includeUnit: includeUnit);
  };
});
