import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../services/exercise_service.dart';

// User Profile Provider
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile());

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void setUnitSystem(String unit) {
    state = state.copyWith(unitSystem: unit);
  }

  void setProfile(UserProfile profile) {
    state = profile;
  }

  void updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    int? age,
    double? weight,
    double? height,
    String? goal,
    String? experienceLevel,
    bool? isProfileComplete,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      age: age,
      weight: weight,
      height: height,
      goal: goal,
      experienceLevel: experienceLevel,
      isProfileComplete: isProfileComplete,
    );
  }

  void reset() {
    state = const UserProfile();
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

// Favorite Exercises Provider
class FavoriteExercisesNotifier extends StateNotifier<Set<String>> {
  FavoriteExercisesNotifier() : super({'ex_1', 'ex_2'}); // Default favorites

  void toggleFavorite(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }
}

final favoriteExercisesProvider = StateNotifierProvider<FavoriteExercisesNotifier, Set<String>>((ref) {
  return FavoriteExercisesNotifier();
});

// Exercise Library Filtering & API Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'All');
final selectedMuscleFilterProvider = StateProvider<String>((ref) => 'All');
final selectedEquipmentFilterProvider = StateProvider<String>((ref) => 'All');

class ExerciseListNotifier extends StateNotifier<AsyncValue<List<Exercise>>> {
  final ExerciseService _exerciseService;

  ExerciseListNotifier(this._exerciseService) : super(const AsyncValue.loading()) {
    loadExercises();
  }

  Future<void> loadExercises({bool forceRefresh = false}) async {
    if (!forceRefresh && state.hasValue && state.value != null && state.value!.isNotEmpty) {
      return;
    }
    state = const AsyncValue.loading();

    try {
      final list = await _exerciseService.fetchAllExercises(forceRefresh: forceRefresh);
      state = AsyncValue.data(list);
    } catch (e, stack) {
      debugPrint('[ExerciseListNotifier] Error loading local dataset: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

final exerciseListProvider = StateNotifierProvider<ExerciseListNotifier, AsyncValue<List<Exercise>>>((ref) {
  final exerciseService = ref.watch(exerciseServiceProvider);
  return ExerciseListNotifier(exerciseService);
});

final filteredExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final exercisesAsync = ref.watch(exerciseListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryFilterProvider);
  final muscle = ref.watch(selectedMuscleFilterProvider);
  final equipment = ref.watch(selectedEquipmentFilterProvider);

  return exercisesAsync.whenData((exercises) {
    return exercises.where((ex) {
      final matchesQuery = query.isEmpty ||
          ex.name.toLowerCase().contains(query) ||
          ex.muscleGroup.toLowerCase().contains(query) ||
          ex.equipment.toLowerCase().contains(query) ||
          (ex.target != null && ex.target!.toLowerCase().contains(query));

      bool matchesCategory = true;
      if (category == 'Strength') {
        matchesCategory = ex.category == ExerciseCategory.strength;
      } else if (category == 'Cardio') {
        matchesCategory = ex.category == ExerciseCategory.cardio;
      }

      bool matchesMuscle = true;
      if (muscle != 'All') {
        matchesMuscle = ex.muscleGroup.toLowerCase().contains(muscle.toLowerCase()) ||
            (ex.bodyPart != null && ex.bodyPart!.toLowerCase().contains(muscle.toLowerCase()));
      }

      bool matchesEquipment = true;
      if (equipment != 'All') {
        matchesEquipment = ex.equipment.toLowerCase().contains(equipment.toLowerCase());
      }

      return matchesQuery && matchesCategory && matchesMuscle && matchesEquipment;
    }).toList();
  });
});

// Active Workout Session Provider
class ActiveWorkoutNotifier extends StateNotifier<List<WorkoutExercise>> {
  ActiveWorkoutNotifier() : super([
    WorkoutExercise(
      exerciseId: 'ex_1',
      exerciseName: 'Barbell Bench Press',
      sets: [
        WorkoutSet(setNumber: 1, reps: 10, weightKg: 50.0, isCompleted: true),
        WorkoutSet(setNumber: 2, reps: 8, weightKg: 60.0, isCompleted: true),
        WorkoutSet(setNumber: 3, reps: 6, weightKg: 60.0, isCompleted: false),
      ],
    ),
  ]);

  void addExercise(Exercise ex) {
    if (state.any((item) => item.exerciseId == ex.id)) return;
    state = [
      ...state,
      WorkoutExercise(
        exerciseId: ex.id,
        exerciseName: ex.name,
        sets: [WorkoutSet(setNumber: 1, reps: 10, weightKg: 40.0)],
      )
    ];
  }

  void addSet(String exerciseId) {
    state = [
      for (final item in state)
        if (item.exerciseId == exerciseId)
          WorkoutExercise(
            exerciseId: item.exerciseId,
            exerciseName: item.exerciseName,
            sets: [
              ...item.sets,
              WorkoutSet(
                setNumber: item.sets.length + 1,
                reps: item.sets.isNotEmpty ? item.sets.last.reps : 10,
                weightKg: item.sets.isNotEmpty ? item.sets.last.weightKg : 40.0,
              ),
            ],
          )
        else
          item,
    ];
  }

  void updateSet(String exerciseId, int setIndex, {int? reps, double? weightKg, bool? isCompleted}) {
    state = [
      for (final item in state)
        if (item.exerciseId == exerciseId)
          WorkoutExercise(
            exerciseId: item.exerciseId,
            exerciseName: item.exerciseName,
            sets: [
              for (int i = 0; i < item.sets.length; i++)
                if (i == setIndex)
                  item.sets[i].copyWith(
                    reps: reps ?? item.sets[i].reps,
                    weightKg: weightKg ?? item.sets[i].weightKg,
                    isCompleted: isCompleted ?? item.sets[i].isCompleted,
                  )
                else
                  item.sets[i],
            ],
          )
        else
          item,
    ];
  }

  void clearWorkout() {
    state = [];
  }
}

final activeWorkoutProvider = StateNotifierProvider<ActiveWorkoutNotifier, List<WorkoutExercise>>((ref) {
  return ActiveWorkoutNotifier();
});

// Timer State Model
class RestTimerState {
  final int secondsRemaining;
  final int totalDuration;
  final bool isRunning;
  final List<String> laps;

  const RestTimerState({
    this.secondsRemaining = 60,
    this.totalDuration = 60,
    this.isRunning = false,
    this.laps = const [],
  });

  RestTimerState copyWith({
    int? secondsRemaining,
    int? totalDuration,
    bool? isRunning,
    List<String>? laps,
  }) {
    return RestTimerState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalDuration: totalDuration ?? this.totalDuration,
      isRunning: isRunning ?? this.isRunning,
      laps: laps ?? this.laps,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(const RestTimerState());

  void _onTimerComplete() {
    _timer?.cancel();
    state = state.copyWith(secondsRemaining: 0, isRunning: false);
    HapticFeedback.heavyImpact();
  }

  void startTimer([int seconds = 60]) {
    _timer?.cancel();
    state = RestTimerState(secondsRemaining: seconds, totalDuration: seconds, isRunning: true, laps: []);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 1) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void togglePauseResume() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
    } else if (state.secondsRemaining > 0) {
      state = state.copyWith(isRunning: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.secondsRemaining > 1) {
          state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
        } else {
          _onTimerComplete();
        }
      });
    }
  }

  void adjustTime(int seconds) {
    final newRemaining = (state.secondsRemaining + seconds).clamp(0, 3600);
    final newTotal = newRemaining > state.totalDuration ? newRemaining : state.totalDuration;
    state = state.copyWith(secondsRemaining: newRemaining, totalDuration: newTotal);
    if (newRemaining == 0 && state.isRunning) {
      _onTimerComplete();
    }
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(secondsRemaining: 0, isRunning: false);
  }

  void addLap() {
    final min = (state.secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final sec = (state.secondsRemaining % 60).toString().padLeft(2, '0');
    final lapTimeStr = '$min:$sec';
    final lapLabel = 'Lap ${state.laps.length + 1} ($lapTimeStr)';
    state = state.copyWith(laps: [...state.laps, lapLabel]);
    HapticFeedback.mediumImpact();
  }

  void reset([int seconds = 60]) {
    _timer?.cancel();
    state = RestTimerState(secondsRemaining: seconds, totalDuration: seconds, isRunning: false, laps: []);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

// Progress Screen Filters & Custom Overrides
final progressSelectedExerciseProvider = StateProvider<String>((ref) => 'Bench Press');
final progressDateRangeProvider = StateProvider<String>((ref) => 'Month');
final customBmiOverrideProvider = StateProvider<double?>((ref) => null);
final customBodyFatOverrideProvider = StateProvider<double?>((ref) => null);

// User Activity & Real Progress Tracking Provider for Badges
class UserActivity {
  final int loggedWorkoutsCount;
  final int currentStreakDays;
  final double maxWeightLiftedKg;
  final Set<String> distinctExercisesTried;
  final bool hasLoggedCardio;
  final bool hasLoggedStrength;
  final Set<int> completedDayNumbers;

  const UserActivity({
    this.loggedWorkoutsCount = 0,
    this.currentStreakDays = 0,
    this.maxWeightLiftedKg = 0.0,
    this.distinctExercisesTried = const {},
    this.hasLoggedCardio = false,
    this.hasLoggedStrength = false,
    this.completedDayNumbers = const {},
  });

  UserActivity copyWith({
    int? loggedWorkoutsCount,
    int? currentStreakDays,
    double? maxWeightLiftedKg,
    Set<String>? distinctExercisesTried,
    bool? hasLoggedCardio,
    bool? hasLoggedStrength,
    Set<int>? completedDayNumbers,
  }) {
    return UserActivity(
      loggedWorkoutsCount: loggedWorkoutsCount ?? this.loggedWorkoutsCount,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      maxWeightLiftedKg: maxWeightLiftedKg ?? this.maxWeightLiftedKg,
      distinctExercisesTried: distinctExercisesTried ?? this.distinctExercisesTried,
      hasLoggedCardio: hasLoggedCardio ?? this.hasLoggedCardio,
      hasLoggedStrength: hasLoggedStrength ?? this.hasLoggedStrength,
      completedDayNumbers: completedDayNumbers ?? this.completedDayNumbers,
    );
  }
}

class UserActivityNotifier extends StateNotifier<UserActivity> {
  UserActivityNotifier() : super(const UserActivity());

  void reset() {
    state = const UserActivity();
  }

  void recordWorkout({
    required List<String> exerciseIds,
    required double maxWeight,
    required bool isCardio,
    required bool isStrength,
  }) {
    final now = DateTime.now();
    final dayNum = now.day;
    final newCount = state.loggedWorkoutsCount + 1;
    final newDays = {...state.completedDayNumbers, dayNum};
    final newStreak = newDays.length;
    final newMaxWeight = maxWeight > state.maxWeightLiftedKg ? maxWeight : state.maxWeightLiftedKg;
    final newExercises = {...state.distinctExercisesTried, ...exerciseIds};

    state = state.copyWith(
      loggedWorkoutsCount: newCount,
      currentStreakDays: newStreak,
      maxWeightLiftedKg: newMaxWeight,
      distinctExercisesTried: newExercises,
      hasLoggedCardio: state.hasLoggedCardio || isCardio,
      hasLoggedStrength: state.hasLoggedStrength || isStrength,
      completedDayNumbers: newDays,
    );
  }
}

final userActivityProvider = StateNotifierProvider<UserActivityNotifier, UserActivity>((ref) {
  return UserActivityNotifier();
});
