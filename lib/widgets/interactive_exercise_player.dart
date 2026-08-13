import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import 'exercise_gif_widget.dart';

/// Clean Exercise Demonstration Display for Gymyzio.
/// Displays official exercise GIFs continuously at original speed
/// without MP4 video controllers, play/pause buttons, or skeleton filters.
class InteractiveExercisePlayer extends StatelessWidget {
  final Exercise exercise;
  final double height;
  final BoxFit fit;

  const InteractiveExercisePlayer({
    super.key,
    required this.exercise,
    this.height = 300.0,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    final primaryTarget = exercise.target?.isNotEmpty == true
        ? exercise.target!.toUpperCase()
        : exercise.muscleGroup.toUpperCase();

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context), width: 1.0),
        boxShadow: AppColors.softGlow(AppColors.primary, opacity: 0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Direct GIF Player Layer (Normal original dataset GIF at actual speed)
          Positioned.fill(
            child: ExerciseGifWidget(
              assetPath: exercise.assetPath,
              gifUrl: exercise.gifUrl,
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              fit: fit,
            ),
          ),

          // 2. Muscle Target Tag Badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    primaryTarget,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
