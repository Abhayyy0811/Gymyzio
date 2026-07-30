class WorkoutSet {
  final int setNumber;
  int reps;
  double weightKg;
  bool isCompleted;

  WorkoutSet({
    required this.setNumber,
    this.reps = 10,
    this.weightKg = 40.0,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({
    int? setNumber,
    int? reps,
    double? weightKg,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}

class CompletedWorkout {
  final String id;
  final String userId;
  final String workoutTitle;
  final DateTime date;
  final int durationMinutes;
  final List<WorkoutExercise> exercises;

  CompletedWorkout({
    required this.id,
    required this.userId,
    required this.workoutTitle,
    required this.date,
    required this.durationMinutes,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutTitle': workoutTitle,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => {
        'exerciseId': e.exerciseId,
        'exerciseName': e.exerciseName,
        'sets': e.sets.map((s) => {
          'setNumber': s.setNumber,
          'reps': s.reps,
          'weightKg': s.weightKg,
          'isCompleted': s.isCompleted,
        }).toList(),
      }).toList(),
    };
  }

  factory CompletedWorkout.fromMap(Map<String, dynamic> map) {
    return CompletedWorkout(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      workoutTitle: map['workoutTitle'] ?? 'Workout',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 0,
      exercises: (map['exercises'] as List<dynamic>? ?? []).map((e) {
        return WorkoutExercise(
          exerciseId: e['exerciseId'] ?? '',
          exerciseName: e['exerciseName'] ?? '',
          sets: (e['sets'] as List<dynamic>? ?? []).map((s) {
            return WorkoutSet(
              setNumber: s['setNumber'] ?? 1,
              reps: s['reps'] ?? 0,
              weightKg: (s['weightKg'] as num?)?.toDouble() ?? 0.0,
              isCompleted: s['isCompleted'] ?? true,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class BodyWeightLog {
  final DateTime date;
  final double weightKg;

  BodyWeightLog({required this.date, required this.weightKg});

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'weightKg': weightKg,
  };

  factory BodyWeightLog.fromMap(Map<String, dynamic> map) {
    return BodyWeightLog(
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
