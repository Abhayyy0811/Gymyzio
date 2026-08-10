import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/dietchamp_model.dart';
import '../services/dietchamp_service.dart';

class DietChampState {
  final DietChampUserPrefs prefs;
  final bool isOnboarded;
  final bool isLoading;
  final Map<String, EatenMealLog> eatenLogs;
  final String dateKey; // Today's date string e.g. "2026_08_05"
  final String dietMode; // 'none' | 'app' | 'custom'
  final bool hasCustomPlan; // Whether a custom plan has been saved

  DietChampState({
    required this.prefs,
    required this.isOnboarded,
    this.isLoading = false,
    this.eatenLogs = const {},
    required this.dateKey,
    this.dietMode = 'none',
    this.hasCustomPlan = false,
  });

  int get totalConsumedCalories =>
      eatenLogs.values.fold(0, (sum, item) => sum + item.calories.round());

  num get totalConsumedProtein =>
      eatenLogs.values.fold(0, (sum, item) => sum + item.protein);

  num get totalConsumedCarbs =>
      eatenLogs.values.fold(0, (sum, item) => sum + item.carbs);

  num get totalConsumedFats =>
      eatenLogs.values.fold(0, (sum, item) => sum + item.fats);

  DietChampState copyWith({
    DietChampUserPrefs? prefs,
    bool? isOnboarded,
    bool? isLoading,
    Map<String, EatenMealLog>? eatenLogs,
    String? dateKey,
    String? dietMode,
    bool? hasCustomPlan,
  }) {
    return DietChampState(
      prefs: prefs ?? this.prefs,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isLoading: isLoading ?? this.isLoading,
      eatenLogs: eatenLogs ?? this.eatenLogs,
      dateKey: dateKey ?? this.dateKey,
      dietMode: dietMode ?? this.dietMode,
      hasCustomPlan: hasCustomPlan ?? this.hasCustomPlan,
    );
  }
}

class DietChampNotifier extends StateNotifier<DietChampState> {
  static const _prefKeyPref = 'dietchamp_preference';
  static const _prefKeyWeight = 'dietchamp_weight_kg';
  static const _prefKeyGoal = 'dietchamp_goal';
  static const _prefKeyOnboarded = 'dietchamp_onboarded';
  static const _prefKeyLastDate = 'dietchamp_last_date';
  static const _prefKeyMode = 'dietchamp_mode';
  static const _prefKeyCustomPlan = 'dietchamp_custom_plan';

  DietChampNotifier()
      : super(
          DietChampState(
            prefs: DietChampUserPrefs(
              preference: 'Veg',
              weightKg: 65.0,
              goal: 'Fat Loss',
            ),
            isOnboarded: false,
            dateKey: _getTodayDateKey(),
          ),
        ) {
    _loadFromPrefs();
  }

  static String _getTodayDateKey() {
    return DateFormat('yyyy_MM_dd').format(DateTime.now());
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayDate = _getTodayDateKey();
      final lastDate = prefs.getString(_prefKeyLastDate) ?? todayDate;

      final savedOnboarded = prefs.getBool(_prefKeyOnboarded) ?? false;
      final savedPreference = prefs.getString(_prefKeyPref) ?? 'Veg';
      final savedWeight = prefs.getDouble(_prefKeyWeight) ?? 65.0;
      final savedGoal = prefs.getString(_prefKeyGoal) ?? 'Fat Loss';
      final savedMode = prefs.getString(_prefKeyMode) ?? 'none';
      final hasCustomPlan = prefs.getString(_prefKeyCustomPlan) != null;

      Map<String, EatenMealLog> loadedLogs = {};

      // Daily Auto-Reset: Check if last active date is different from today
      if (lastDate == todayDate) {
        final logsJsonStr = prefs.getString('dietchamp_eaten_logs_$todayDate');
        if (logsJsonStr != null) {
          final decoded = jsonDecode(logsJsonStr) as Map<String, dynamic>;
          decoded.forEach((key, val) {
            loadedLogs[key] = EatenMealLog.fromJson(val as Map<String, dynamic>);
          });
        }
      } else {
        // Automatically reset for new day after midnight 12:00 AM
        await prefs.setString(_prefKeyLastDate, todayDate);
      }

      state = DietChampState(
        prefs: DietChampUserPrefs(
          preference: savedPreference,
          weightKg: savedWeight,
          goal: savedGoal,
        ),
        isOnboarded: savedOnboarded,
        eatenLogs: loadedLogs,
        dateKey: todayDate,
        dietMode: savedMode,
        hasCustomPlan: hasCustomPlan,
      );
    } catch (_) {}
  }

  Future<void> setMode(String mode) async {
    state = state.copyWith(dietMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyMode, mode);
    } catch (_) {}
  }

  Future<void> resetMode() async {
    state = state.copyWith(dietMode: 'none', isOnboarded: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyMode, 'none');
      await prefs.setBool(_prefKeyOnboarded, false);
    } catch (_) {}
  }

  Future<void> saveCustomPlan(DietPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(plan.toJson());
      await prefs.setString(_prefKeyCustomPlan, jsonStr);
      state = state.copyWith(hasCustomPlan: true);
    } catch (_) {}
  }

  Future<DietPlan?> loadCustomPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKeyCustomPlan);
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return DietPlan.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteCustomPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyCustomPlan);
      state = state.copyWith(hasCustomPlan: false);
    } catch (_) {}
  }

  Future<void> toggleItemEaten({
    required String mealCategory,
    required DietMealItem item,
  }) async {
    final todayDate = _getTodayDateKey();
    final updatedLogs = Map<String, EatenMealLog>.from(state.eatenLogs);

    if (updatedLogs.containsKey(item.id)) {
      updatedLogs.remove(item.id);
    } else {
      updatedLogs[item.id] = EatenMealLog(
        itemId: item.id,
        mealCategory: mealCategory,
        name: item.name,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fats: item.fats,
        eatenAt: DateTime.now(),
      );
    }

    state = state.copyWith(eatenLogs: updatedLogs, dateKey: todayDate);

    // Save to SharedPreferences locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastDate, todayDate);

      final encodedMap = <String, dynamic>{};
      updatedLogs.forEach((key, val) {
        encodedMap[key] = val.toJson();
      });

      await prefs.setString('dietchamp_eaten_logs_$todayDate', jsonEncode(encodedMap));
    } catch (_) {}
  }

  Future<void> savePreferences({
    required String preference,
    required double weightKg,
    required String goal,
  }) async {
    state = state.copyWith(isLoading: true);
    final newPrefs = DietChampUserPrefs(
      preference: preference,
      weightKg: weightKg,
      goal: goal,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyPref, preference);
      await prefs.setDouble(_prefKeyWeight, weightKg);
      await prefs.setString(_prefKeyGoal, goal);
      await prefs.setBool(_prefKeyOnboarded, true);
    } catch (_) {}

    state = state.copyWith(
      prefs: newPrefs,
      isOnboarded: true,
      isLoading: false,
    );
  }

  void editPreferences() {
    state = state.copyWith(isOnboarded: false);
  }

  void editCustomPlan() {
    state = state.copyWith(hasCustomPlan: false);
  }

  Future<void> resetTodayMeals() async {
    final todayDate = _getTodayDateKey();
    state = state.copyWith(eatenLogs: {}, dateKey: todayDate);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dietchamp_eaten_logs_$todayDate');
    } catch (_) {}
  }
}

final dietChampNotifierProvider =
    StateNotifierProvider<DietChampNotifier, DietChampState>((ref) {
  return DietChampNotifier();
});

final dietChampPlanProvider = FutureProvider<DietPlan>((ref) async {
  final state = ref.watch(dietChampNotifierProvider);
  return await DietChampService.fetchDietPlan(
    preference: state.prefs.preference,
    weightKg: state.prefs.weightKg,
    goal: state.prefs.goal,
  );
});

final customDietPlanProvider = FutureProvider<DietPlan?>((ref) async {
  final notifier = ref.watch(dietChampNotifierProvider.notifier);
  return await notifier.loadCustomPlan();
});
