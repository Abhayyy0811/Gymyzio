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
