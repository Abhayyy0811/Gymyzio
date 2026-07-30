import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_providers.dart';
import '../l10n/app_strings.dart';
import '../utils/unit_converter.dart';

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
