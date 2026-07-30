import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../models/exercise.dart';
import '../widgets/exercise_gif_widget.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    final exerciseList = exercisesAsync.asData?.value ?? [];
    if (exerciseList.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Exercise Detail')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final exercise = exerciseList.firstWhere(
      (e) => e.id == widget.exerciseId,
      orElse: () => exerciseList.first,
    );

    final favorites = ref.watch(favoriteExercisesProvider);
    final isFavorite = favorites.contains(exercise.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFavorite ? AppColors.primary : AppColors.textPrimary,
              size: 26,
            ),
            onPressed: () {
              ref.read(favoriteExercisesProvider.notifier).toggleFavorite(exercise.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite ? 'Removed from favorites' : 'Saved to favorites'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Real Animated GIF Demonstration Banner
            _buildGifHeaderBanner(exercise),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Tags Row
                  Row(
                    children: [
                      _buildMetaBadge('Target: ${exercise.muscleGroup}', AppColors.primary, Icons.fitness_center),
                      const SizedBox(width: 8),
                      _buildMetaBadge('Level: ${exercise.difficulty}', AppColors.secondary, Icons.bar_chart),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Equipment: ${exercise.equipment}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),

                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Secondary Muscles: ${exercise.secondaryMuscles.join(", ")}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Real API Step-by-Step Instructions List
                  const Text(
                    'Step-by-Step Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (exercise.instructions.isEmpty)
                    const Text('No instructions specified for this exercise.', style: TextStyle(color: AppColors.textMuted))
                  else
                    ...exercise.instructions.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final text = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(fontSize: 15, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Common Mistakes ExpansionTile
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                          title: const Text(
                            'Form Safety & Pro Tips',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              child: Column(
                                children: exercise.commonMistakes.map((mistake) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            mistake,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // "Add to Workout" Button
                  AppBouncyTap(
                    onTap: () {
                      ref.read(activeWorkoutProvider.notifier).addExercise(exercise);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('${exercise.name} added to active workout!'),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.accent,
                          action: SnackBarAction(
                            label: 'VIEW',
                            textColor: Colors.black,
                            onPressed: () => context.push('/workout-logging'),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: AppColors.primaryGlow, blurRadius: 16)],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_task_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Add to Workout Logging',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGifHeaderBanner(Exercise exercise) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: AppColors.softGlow(exercise.themeColor, opacity: 0.2, blur: 16),
      ),
      child: ExerciseGifWidget(
        assetPath: exercise.assetPath,
        gifUrl: exercise.gifUrl,
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildMetaBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
