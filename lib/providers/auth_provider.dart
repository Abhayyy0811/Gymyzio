import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/workout_session.dart';
import '../providers/app_state_providers.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for UserProfileService singleton
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

/// StreamProvider watching Firebase authStateChanges()
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Flag indicating if active user is a new user (needs onboarding)
final isNewUserProvider = StateProvider<bool>((ref) => false);

/// Provider for the active Firebase User
final currentUserProvider = Provider<User?>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value ?? ref.watch(authServiceProvider).getCurrentUser();
});

/// Provider for User Display Name with fallback to profile name
final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  final profileName = ref.watch(userProfileProvider).name;
  if (user?.displayName != null && user!.displayName!.isNotEmpty) {
    return user.displayName!;
  }
  if (profileName.isNotEmpty && profileName != 'Athlete') {
    return profileName;
  }
  return 'Athlete';
});

/// Provider for User Email with fallback
final userEmailProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  final profileEmail = ref.watch(userProfileProvider).email;
  if (user?.email != null && user!.email!.isNotEmpty) {
    return user.email!;
  }
  if (profileEmail != null && profileEmail.isNotEmpty) {
    return profileEmail;
  }
  return 'No email registered';
});

/// StateNotifier for custom user-uploaded photo URL (persisted in SharedPreferences)
class CustomPhotoUrlNotifier extends StateNotifier<String?> {
  final String _uid;
  CustomPhotoUrlNotifier(this._uid) : super(null) {
    _load();
  }

  static String _key(String uid) => 'custom_photo_url_$uid';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key(_uid));
      if (saved != null && saved.isNotEmpty) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> setPhoto(String dataUrl) async {
    state = dataUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(_uid), dataUrl);
    } catch (_) {}
  }

  Future<void> clearPhoto() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(_uid));
    } catch (_) {}
  }
}

final customPhotoUrlProvider = StateNotifierProvider<CustomPhotoUrlNotifier, String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return CustomPhotoUrlNotifier(user?.uid ?? '');
});

/// Provider for User Photo URL — prefers custom uploaded photo, falls back to Firebase Auth photo
final userPhotoUrlProvider = Provider<String?>((ref) {
  final customPhoto = ref.watch(customPhotoUrlProvider);
  if (customPhoto != null && customPhoto.isNotEmpty) return customPhoto;
  final user = ref.watch(currentUserProvider);
  return user?.photoURL;
});

/// StreamProvider watching Real-Time Completed Workouts from Firestore
final completedWorkoutsProvider = StreamProvider<List<CompletedWorkout>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final profileService = ref.watch(userProfileServiceProvider);
  return profileService.streamCompletedWorkouts(user.uid);
});

/// StreamProvider watching Real-Time Body Weight Logs from Firestore
final bodyWeightLogsProvider = StreamProvider<List<BodyWeightLog>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final profileService = ref.watch(userProfileServiceProvider);
  return profileService.streamBodyWeightLogs(user.uid);
});

/// Local Persistent Workout History Provider
class WorkoutHistoryNotifier extends StateNotifier<List<CompletedWorkout>> {
  WorkoutHistoryNotifier() : super([]) {
    _loadFromLocal();
  }

  static const _storageKey = 'gymyzio_local_workout_history_v1';

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        state = list.map((item) => CompletedWorkout.fromMap(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Error loading local workout history: $e');
    }
  }

  Future<void> _saveToLocal(List<CompletedWorkout> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((w) => w.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) print('⚠️ Error saving local workout history: $e');
    }
  }

  void addWorkout(CompletedWorkout workout) {
    state = [...state, workout];
    _saveToLocal(state);
  }
}

final workoutHistoryProvider = StateNotifierProvider<WorkoutHistoryNotifier, List<CompletedWorkout>>((ref) {
  return WorkoutHistoryNotifier();
});

/// Combined Real-Time Provider (Local + Firestore)
final allWorkoutsProvider = Provider<List<CompletedWorkout>>((ref) {
  final localHistory = ref.watch(workoutHistoryProvider);
  final firestoreHistoryAsync = ref.watch(completedWorkoutsProvider);
  final firestoreHistory = firestoreHistoryAsync.value ?? [];

  final Map<String, CompletedWorkout> mergedMap = {};
  for (final w in localHistory) {
    mergedMap[w.id] = w;
  }
  for (final w in firestoreHistory) {
    mergedMap[w.id] = w;
  }

  final list = mergedMap.values.toList();
  list.sort((a, b) => a.date.compareTo(b.date));
  return list;
});
