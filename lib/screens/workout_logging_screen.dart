import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/shine_button.dart';
import '../models/workout_session.dart';
import '../utils/unit_converter.dart';

class WorkoutLoggingScreen extends ConsumerStatefulWidget {
  const WorkoutLoggingScreen({super.key});

  @override
  ConsumerState<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends ConsumerState<WorkoutLoggingScreen> {
  bool _showInstructionHint = true;

  @override
  void initState() {
    super.initState();
    _checkHintPreference();
  }

  Future<void> _checkHintPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool('hide_workout_logging_hint') ?? false;
    if (mounted && hidden) {
      setState(() => _showInstructionHint = false);
    }
  }

  Future<void> _dismissHint() async {
    setState(() => _showInstructionHint = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_workout_logging_hint', true);
  }

  @override
  Widget build(BuildContext context) {
    final workoutList = ref.watch(activeWorkoutProvider);
    final tr = ref.watch(trProvider);
    final unitSystem = ref.watch(appUnitSystemProvider);
    final formatWeight = ref.watch(weightFormatterProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr('active_session'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
              tooltip: 'How to use',
              onPressed: () {
                setState(() => _showInstructionHint = true);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // First-Time Dismissible "How to use" Instructional Info Banner
            if (_showInstructionHint)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'How to use: Add exercises from the Library, log your sets/weight, and use the rest timer between sets — tap the timer bubble to start.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _dismissHint,
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

            // Redesigned Reusable Rest Timer Widget
            const RestTimerWidget(),

            // Exercise List with Sets & Reps Steppers
            Expanded(
              child: workoutList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center_outlined, size: 64, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('No exercises added yet.', style: TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('Browse library to add exercises to your session.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: workoutList.length,
                      itemBuilder: (context, exIndex) {
                        final item = workoutList[exIndex];
                        return _buildExerciseWorkoutCard(context, item, tr, unitSystem, formatWeight);
                      },
                    ),
            ),

            // Bottom Finish Workout Action Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShineButton(
                onTap: () => _finishWorkoutDialog(context, tr),
                gradient: AppColors.primaryGradient,
                glowColor: AppColors.primaryGlow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      tr('finish_workout'),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseWorkoutCard(
    BuildContext context,
    WorkoutExercise item,
    String Function(String) tr,
    String unitSystem,
    String Function(double, {int decimals, bool includeUnit}) formatWeight,
  ) {
    final weightUnitLabel = UnitConverter.weightUnit(unitSystem).toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header with Exercise Thumbnail & Add Set Button
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.exerciseName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                AppBouncyTap(
                  onTap: () {
                    ref.read(activeWorkoutProvider.notifier).addSet(item.exerciseId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(tr('add_set'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Header labels with dynamic WEIGHT unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text(tr('table_set'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                  Expanded(child: Center(child: Text('${tr('table_weight')} ($weightUnitLabel)', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text(tr('table_reps'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)))),
                  SizedBox(width: 40, child: Center(child: Text(tr('table_done'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 16),

            // Sets list rows
            ...item.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final workoutSet = entry.value;
              final weightDisplay = formatWeight(workoutSet.weightKg);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    // Set Number Badge
                    SizedBox(
                      width: 40,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${workoutSet.setNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),

                    // Weight Stepper (- / +)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMiniStepperButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (workoutSet.weightKg > 2.5) {
                                ref.read(activeWorkoutProvider.notifier).updateSet(
                                      item.exerciseId,
                                      setIndex,
                                      weightKg: workoutSet.weightKg - 2.5,
                                    );
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              weightDisplay,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          _buildMiniStepperButton(
                            icon: Icons.add,
                            onTap: () {
                              ref.read(activeWorkoutProvider.notifier).updateSet(
                                    item.exerciseId,
                                    setIndex,
                                    weightKg: workoutSet.weightKg + 2.5,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Reps Stepper (- / +)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMiniStepperButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (workoutSet.reps > 1) {
                                ref.read(activeWorkoutProvider.notifier).updateSet(
                                      item.exerciseId,
                                      setIndex,
                                      reps: workoutSet.reps - 1,
                                    );
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${workoutSet.reps}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          _buildMiniStepperButton(
                            icon: Icons.add,
                            onTap: () {
                              ref.read(activeWorkoutProvider.notifier).updateSet(
                                    item.exerciseId,
                                    setIndex,
                                    reps: workoutSet.reps + 1,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Checkbox Done Button
                    SizedBox(
                      width: 40,
                      child: Checkbox(
                        value: workoutSet.isCompleted,
                        activeColor: AppColors.accent,
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (bool? val) {
                          ref.read(activeWorkoutProvider.notifier).updateSet(
                                item.exerciseId,
                                setIndex,
                                isCompleted: val ?? false,
                              );
                          if (val == true) {
                            ref.read(restTimerProvider.notifier).startTimer(60);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStepperButton({required IconData icon, required VoidCallback onTap}) {
    return AppBouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }

  void _finishWorkoutDialog(BuildContext context, String Function(String) tr) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.military_tech_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(tr('workout_completed'))),
          ],
        ),
        content: Text(
          tr('workout_completed_sub'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final workoutList = ref.read(activeWorkoutProvider);
              double maxWeight = 0.0;
              final List<String> exIds = [];
              bool isCardio = false;
              bool isStrength = false;

              for (final item in workoutList) {
                exIds.add(item.exerciseId);
                for (final set in item.sets) {
                  if (set.weightKg > maxWeight) maxWeight = set.weightKg;
                }
                if (item.exerciseName.toLowerCase().contains('run') || item.exerciseName.toLowerCase().contains('cardio')) {
                  isCardio = true;
                } else {
                  isStrength = true;
                }
              }

              ref.read(userActivityProvider.notifier).recordWorkout(
                exerciseIds: exIds,
                maxWeight: maxWeight,
                isCardio: isCardio,
                isStrength: isStrength,
              );
              ref.read(activeWorkoutProvider.notifier).clearWorkout();

              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Workout saved! Achievements & progress updated 🔥'),
                  backgroundColor: AppColors.accent,
                ),
              );
              context.go('/badges');
            },
            child: Text(tr('return_home'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
