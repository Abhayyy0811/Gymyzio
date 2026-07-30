import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/app_settings_provider.dart';
import '../models/exercise.dart';
import '../data/dummy_data.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final tr = ref.watch(trProvider);
    final formatWeight = ref.watch(weightFormatterProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Parallax Header SliverAppBar with Layered Pattern
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  '${tr('welcome')}, ${profile.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 12)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: Base Gradient
                    // Layer 1: Base Royal Blue Gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    // Vignette Gradient Mask
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.7),
                            AppColors.background,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Layer 3: Watermark Dumbbell Icon Accent Graphic
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Opacity(
                        opacity: 0.12,
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 200,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    // Layer 5: Goal Badge Overlay
                    Positioned(
                      left: 20,
                      top: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                          boxShadow: AppColors.softGlow(AppColors.secondary, opacity: 0.25, blur: 10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: AppColors.secondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${tr('goal')}: ${profile.goal} (${profile.experienceLevel})',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dashboard Content List with Entrance Micro-Animations
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak Banner Card with Fire Glow Accent
                    _buildStreakCard(context, ref, tr)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),

                    // Quick Start Section Title
                    Text(
                      tr('quick_start'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 14),

                    // 3 Quick-Start Buttons Grid/Row
                    _buildQuickStartButtons(context, ref, tr)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 28),

                    // Recent PR Card
                    Text(
                      tr('recent_pr'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 14),
                    _buildPRCard(context, ref, formatWeight)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: 28),

                    // Today's Recommendation Card
                    _buildRecommendationCard(context, tr)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, WidgetRef ref, String Function(String) tr) {
    final streakDays = ref.watch(userActivityProvider).currentStreakDays;
    const fireGlowColor = Color(0xFFFF5E36);

    return AppBouncyTap(
      onTap: () => context.go('/badges'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.darkCardGradient,
          borderRadius: BorderRadius.circular(AppRadius.container),
          border: Border.all(color: fireGlowColor.withValues(alpha: 0.6), width: 1.5),
          boxShadow: AppColors.softGlow(fireGlowColor, opacity: 0.25, blur: 18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E36), Color(0xFFFF9100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: AppColors.softGlow(fireGlowColor, opacity: 0.5, blur: 12),
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$streakDays ${tr('day_streak')}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('streak_banner_sub'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartButtons(BuildContext context, WidgetRef ref, String Function(String) tr) {
    final exercises = ref.watch(exerciseListProvider).asData?.value ?? [];

    return Column(
      children: [
        // Button 1: Start Strength Workout
        AppBouncyTap(
          onTap: () {
            if (exercises.isNotEmpty) {
              ref.read(activeWorkoutProvider.notifier).addExercise(exercises[0]);
            }
            context.push('/workout-logging');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.homeAccent.withValues(alpha: 0.3)),
              boxShadow: AppColors.softGlow(AppColors.homeAccent, opacity: 0.12, blur: 10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.homeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.homeAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('start_strength'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(tr('start_strength_sub'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill_rounded, color: AppColors.homeAccent, size: 32),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Button 2: Start Cardio Session
        AppBouncyTap(
          onTap: () {
            if (exercises.isNotEmpty) {
              final cardioEx = exercises.firstWhere(
                (e) => e.category == ExerciseCategory.cardio,
                orElse: () => exercises.first,
              );
              ref.read(activeWorkoutProvider.notifier).addExercise(cardioEx);
            }
            context.push('/workout-logging');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              boxShadow: AppColors.softGlow(AppColors.secondary, opacity: 0.12, blur: 10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_run, color: AppColors.secondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('start_cardio'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(tr('start_cardio_sub'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill_rounded, color: AppColors.secondary, size: 32),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Button 3: Browse Library
        AppBouncyTap(
          onTap: () => context.go('/library'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              boxShadow: AppColors.softGlow(AppColors.accent, opacity: 0.1, blur: 10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.explore_rounded, color: AppColors.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('browse_library'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(tr('browse_library_sub'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPRCard(
    BuildContext context,
    WidgetRef ref,
    String Function(double, {int decimals, bool includeUnit}) formatWeight,
  ) {
    final pr = DummyData.recentPRs[0];
    final rawRecord = pr['record']!;
    String formattedRecord = rawRecord;

    final match = RegExp(r'(\d+(?:\.\d+)?)kg').firstMatch(rawRecord);
    if (match != null) {
      final kgVal = double.tryParse(match.group(1)!) ?? 60.0;
      final weightStr = formatWeight(kgVal);
      formattedRecord = rawRecord.replaceFirst(match.group(0)!, weightStr);
    }

    const goldColor = Color(0xFFFFD700);

    return AppBouncyTap(
      onTap: () => context.go('/progress'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: goldColor.withValues(alpha: 0.4)),
          boxShadow: AppColors.softGlow(goldColor, opacity: 0.15, blur: 14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: goldColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pr['exercise']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    formattedRecord,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pr['date']!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary.withValues(alpha: 0.15), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.container),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        boxShadow: AppColors.softGlow(AppColors.secondary, opacity: 0.12, blur: 12),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: AppColors.secondary, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('pro_tip'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary)),
                const SizedBox(height: 4),
                Text(
                  tr('pro_tip_sub'),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
