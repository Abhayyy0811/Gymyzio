import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';

/// 100% Local, Offline Exercise Service reading directly from bundled assets/data/exercises.json.
/// Permanently eliminates network errors, 403s, rate limits, and network latency.
class ExerciseService {
  List<Exercise>? _cachedExercises;

  /// Load exercises from bundled assets/data/exercises.json
  Future<List<Exercise>> fetchAllExercises({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedExercises != null && _cachedExercises!.isNotEmpty) {
      return _cachedExercises!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/exercises.json');
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

      _cachedExercises = jsonList
          .map((item) => Exercise.fromMap(item as Map<String, dynamic>))
          .toList();

      return _cachedExercises!;
    } catch (e) {
      throw Exception('Failed to load local exercise dataset from assets/data/exercises.json: $e');
    }
  }

  /// Compatibility wrapper for existing provider method calls
  Future<List<Exercise>> fetchExercises({
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    return fetchAllExercises(forceRefresh: forceRefresh);
  }
}

final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  return ExerciseService();
});
