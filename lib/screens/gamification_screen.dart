import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state_providers.dart';
import '../data/dummy_data.dart';
import '../models/badge_item.dart';
import '../widgets/app_notification_bell.dart';

import '../widgets/responsive_web_wrapper.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  static bool areLowerTiersCompleted(UserActivity activity) {
    final lowerBadges = DummyData.badges.where((b) => b.tier != BadgeTier.legendary).toList();
    return lowerBadges.every((b) => isBadgeUnlocked(b, activity));
  }

  static int countUnlockedLowerBadges(UserActivity activity) {
    final lowerBadges = DummyData.badges.where((b) => b.tier != BadgeTier.legendary).toList();
    return lowerBadges.where((b) => isBadgeUnlocked(b, activity)).length;
  }

  static bool isBadgeUnlocked(BadgeItem badge, UserActivity activity) {
    if (activity.unlockedBadgeIds.contains(badge.id)) {
      return true;
    }

    if (badge.tier == BadgeTier.legendary && !areLowerTiersCompleted(activity)) {
      return false;
    }

    switch (badge.id) {
      case 'badge_1':
        return activity.loggedWorkoutsCount >= 1;
      case 'badge_2':
        return activity.currentStreakDays >= 3;
      case 'badge_3':
        return activity.currentStreakDays >= 5;
      case 'badge_4':
        return activity.maxWeightLiftedKg >= 50.0;
      case 'badge_5':
        return activity.distinctExercisesTried.length >= 3;
      case 'badge_l6':
        return activity.loggedWorkoutsCount >= 2;
      case 'badge_l7':
        return activity.loggedWorkoutsCount >= 1;
      case 'badge_l8':
        return activity.hasLoggedCardio;
      case 'badge_l9':
        return activity.distinctExercisesTried.length >= 5;
      case 'badge_l10':
        return activity.loggedWorkoutsCount >= 3;

      case 'badge_6':
        return activity.currentStreakDays >= 7;
      case 'badge_7':
        return activity.loggedWorkoutsCount >= 10;
      case 'badge_8':
        return activity.hasLoggedCardio;
      case 'badge_9':
        return activity.maxWeightLiftedKg >= 100.0;
      case 'badge_10':
        return activity.hasLoggedStrength && activity.hasLoggedCardio;
      case 'badge_m6':
        return activity.currentStreakDays >= 14;
      case 'badge_m7':
        return activity.loggedWorkoutsCount >= 25;
      case 'badge_m8':
        return activity.maxWeightLiftedKg >= 120.0;
      case 'badge_m9':
        return activity.distinctExercisesTried.length >= 8;
      case 'badge_m10':
        return activity.hasLoggedCardio && activity.loggedWorkoutsCount >= 5;

      case 'badge_11':
        return activity.currentStreakDays >= 30;
      case 'badge_12':
        return activity.loggedWorkoutsCount >= 100;
      case 'badge_13':
        return activity.hasLoggedCardio && activity.loggedWorkoutsCount >= 15;
      case 'badge_14':
        return activity.maxWeightLiftedKg >= 140.0;
      case 'badge_15':
        return activity.loggedWorkoutsCount >= 50 && activity.currentStreakDays >= 14;
      case 'badge_h6':
        return activity.currentStreakDays >= 60;
      case 'badge_h7':
        return activity.maxWeightLiftedKg >= 150.0;
      case 'badge_h8':
        return activity.loggedWorkoutsCount >= 50;
      case 'badge_h9':
        return activity.distinctExercisesTried.length >= 15;
      case 'badge_h10':
        return activity.hasLoggedCardio && activity.loggedWorkoutsCount >= 10;

      case 'badge_16':
        return activity.maxWeightLiftedKg >= 180.0 && activity.loggedWorkoutsCount >= 150;
      case 'badge_17':
        return activity.currentStreakDays >= 365;
      case 'badge_18':
        return activity.distinctExercisesTried.length >= 20;
      case 'badge_19':
        return activity.loggedWorkoutsCount >= 200;
      case 'badge_leg5':
        return activity.maxWeightLiftedKg >= 220.0;
      case 'badge_leg6':
        return activity.currentStreakDays >= 500;
      case 'badge_leg7':
        return activity.loggedWorkoutsCount >= 300;
      case 'badge_leg8':
        return activity.hasLoggedCardio && activity.loggedWorkoutsCount >= 25;
      case 'badge_leg9':
        return activity.distinctExercisesTried.length >= 25;
      case 'badge_leg10':
        return activity.loggedWorkoutsCount >= 250;
      default:
        return false;
    }
  }

  static String getBadgeProgressLabel(BadgeItem badge, UserActivity activity, bool isUnlocked) {
    if (isUnlocked) return 'Unlocked 🎉';
    if (badge.tier == BadgeTier.legendary && !areLowerTiersCompleted(activity)) {
      return 'Tier Locked 🔒';
    }
    switch (badge.id) {
      case 'badge_1':
        return '${activity.loggedWorkoutsCount}/1 Workout';
      case 'badge_2':
        return '${activity.currentStreakDays}/3d Streak';
      case 'badge_3':
        return '${activity.currentStreakDays}/5d Streak';
      case 'badge_4':
        return '${activity.maxWeightLiftedKg.toStringAsFixed(0)}/50kg Lift';
      case 'badge_5':
        return '${activity.distinctExercisesTried.length}/3 Exercises';
      case 'badge_6':
        return '${activity.currentStreakDays}/7d Streak';
      case 'badge_7':
        return '${activity.loggedWorkoutsCount}/10 Workouts';
      case 'badge_8':
        return activity.hasLoggedCardio ? 'Unlocked 🎉' : 'Log Cardio';
      case 'badge_9':
        return '${activity.maxWeightLiftedKg.toStringAsFixed(0)}/100kg Lift';
      case 'badge_10':
        return 'Strength & Cardio';
      case 'badge_11':
        return '${activity.currentStreakDays}/30d Streak';
      case 'badge_12':
        return '${activity.loggedWorkoutsCount}/100 Workouts';
      case 'badge_13':
        return 'Cardio & 15 Sessions';
      case 'badge_14':
        return '${activity.maxWeightLiftedKg.toStringAsFixed(0)}/140kg Lift';
      case 'badge_15':
        return '${activity.loggedWorkoutsCount}/50 Workouts';
      case 'badge_16':
        return '${activity.maxWeightLiftedKg.toStringAsFixed(0)}/180kg Lift';
      case 'badge_17':
        return '${activity.currentStreakDays}/365d Streak';
      case 'badge_18':
        return '${activity.distinctExercisesTried.length}/20 Exercises';
      case 'badge_19':
        return '${activity.loggedWorkoutsCount}/200 Workouts';
      default:
        return 'Locked';
    }
  }

  static BadgeTaskInfo getBadgeTaskInfo(BadgeItem badge, UserActivity activity, bool isUnlocked) {
    if (isUnlocked) {
      return const BadgeTaskInfo(
        taskInstructions: 'Congratulations! You have fulfilled all requirements and unlocked this achievement badge.',
        actionButtonText: 'View Workout Log',
        routePath: '/workout-logging',
        actionIcon: Icons.check_circle_outline_rounded,
        progressRatio: 1.0,
        currentValText: 'Unlocked 🎉',
        targetValText: '100% Completed',
      );
    }

    switch (badge.id) {
      case 'badge_1': // First Step
        final current = activity.loggedWorkoutsCount;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "First Step", complete and save your very first workout session in the logger.',
          actionButtonText: 'Log First Workout',
          routePath: '/workout-logging',
          actionIcon: Icons.play_arrow_rounded,
          progressRatio: (current / 1.0).clamp(0.0, 1.0),
          currentValText: '$current workout logged',
          targetValText: '1 workout required',
        );

      case 'badge_2': // 3-Day Warrior
        final streak = activity.currentStreakDays;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "3-Day Warrior", log daily workouts for 3 consecutive days to build momentum.',
          actionButtonText: 'Log Workout Today',
          routePath: '/workout-logging',
          actionIcon: Icons.local_fire_department_rounded,
          progressRatio: (streak / 3.0).clamp(0.0, 1.0),
          currentValText: '$streak days active streak',
          targetValText: '3 days streak required',
        );

      case 'badge_3': // High Five
        final streak = activity.currentStreakDays;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "High Five", maintain an active workout streak of 5 consecutive days.',
          actionButtonText: 'Keep Streak Alive',
          routePath: '/workout-logging',
          actionIcon: Icons.thumb_up_alt_rounded,
          progressRatio: (streak / 5.0).clamp(0.0, 1.0),
          currentValText: '$streak days active streak',
          targetValText: '5 days streak required',
        );

      case 'badge_4': // First 50kg Lift
        final weight = activity.maxWeightLiftedKg;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "First 50kg Lift", record any set with a weight of 50kg or higher (e.g. Bench Press, Squat).',
          actionButtonText: 'Log 50kg+ Lift',
          routePath: '/workout-logging',
          actionIcon: Icons.fitness_center_rounded,
          progressRatio: (weight / 50.0).clamp(0.0, 1.0),
          currentValText: '${weight.toStringAsFixed(0)} kg max lift',
          targetValText: '50 kg milestone required',
        );

      case 'badge_5': // Curious Explorer
        final count = activity.distinctExercisesTried.length;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Curious Explorer", explore the exercise library and complete sets in at least 3 distinct exercises.',
          actionButtonText: 'Explore Exercise Library',
          routePath: '/library',
          actionIcon: Icons.explore_rounded,
          progressRatio: (count / 3.0).clamp(0.0, 1.0),
          currentValText: '$count/3 distinct exercises tried',
          targetValText: '3 exercises required',
        );

      case 'badge_6': // 7-Day Champion
        final streak = activity.currentStreakDays;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "7-Day Champion", maintain a perfect 7-day workout streak without missing a day.',
          actionButtonText: 'Log Today\'s Session',
          routePath: '/workout-logging',
          actionIcon: Icons.emoji_events_rounded,
          progressRatio: (streak / 7.0).clamp(0.0, 1.0),
          currentValText: '$streak/7 days streak',
          targetValText: '7 days streak required',
        );

      case 'badge_7': // Iron Titan
        final count = activity.loggedWorkoutsCount;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Iron Titan", complete and log a total of 10 strength workout sessions.',
          actionButtonText: 'Log Strength Session',
          routePath: '/workout-logging',
          actionIcon: Icons.fitness_center_rounded,
          progressRatio: (count / 10.0).clamp(0.0, 1.0),
          currentValText: '$count/10 sessions completed',
          targetValText: '10 strength sessions required',
        );

      case 'badge_8': // 5K Runner
        final hasCardio = activity.hasLoggedCardio;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "5K Runner", log a cardio exercise session (Run, Treadmill, or Outdoor Cycling).',
          actionButtonText: 'Log Cardio Session',
          routePath: '/workout-logging',
          actionIcon: Icons.directions_run_rounded,
          progressRatio: hasCardio ? 1.0 : 0.0,
          currentValText: hasCardio ? 'Done' : 'No cardio logged yet',
          targetValText: '1 Cardio session required',
        );

      case 'badge_9': // Century Lifter
        final weight = activity.maxWeightLiftedKg;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Century Lifter", hit a massive 100kg+ milestone lift on Squat, Deadlift, or Bench Press.',
          actionButtonText: 'Log 100kg PR Lift',
          routePath: '/workout-logging',
          actionIcon: Icons.bolt_rounded,
          progressRatio: (weight / 100.0).clamp(0.0, 1.0),
          currentValText: '${weight.toStringAsFixed(0)} kg max lift',
          targetValText: '100 kg milestone required',
        );

      case 'badge_10': // Hybrid Athlete
        final hasCardio = activity.hasLoggedCardio;
        final hasStrength = activity.hasLoggedStrength;
        final ratio = (hasCardio ? 0.5 : 0.0) + (hasStrength ? 0.5 : 0.0);
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Hybrid Athlete", log both a Strength workout and a Cardio workout session in your log.',
          actionButtonText: 'Log Workout Session',
          routePath: '/workout-logging',
          actionIcon: Icons.attractions_rounded,
          progressRatio: ratio,
          currentValText: '${(ratio * 100).toInt()}% completed',
          targetValText: 'Strength & Cardio required',
        );

      case 'badge_11': // 30-Day Master
        final streak = activity.currentStreakDays;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "30-Day Master", build unbroken discipline by logging daily workouts for 30 consecutive days.',
          actionButtonText: 'Continue 30-Day Goal',
          routePath: '/workout-logging',
          actionIcon: Icons.stars_rounded,
          progressRatio: (streak / 30.0).clamp(0.0, 1.0),
          currentValText: '$streak/30 days streak',
          targetValText: '30 days streak required',
        );

      case 'badge_12': // Century Club
        final count = activity.loggedWorkoutsCount;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Century Club", complete and log a grand total of 100 workouts.',
          actionButtonText: 'Log Workout Session',
          routePath: '/workout-logging',
          actionIcon: Icons.military_tech_rounded,
          progressRatio: (count / 100.0).clamp(0.0, 1.0),
          currentValText: '$count/100 workouts',
          targetValText: '100 total workouts required',
        );

      case 'badge_13': // 10K Endurance
        final count = activity.loggedWorkoutsCount;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "10K Endurance", log 15 total workout sessions and complete a long-distance cardio run.',
          actionButtonText: 'Log Endurance Cardio',
          routePath: '/workout-logging',
          actionIcon: Icons.directions_run_rounded,
          progressRatio: (count / 15.0).clamp(0.0, 1.0),
          currentValText: '$count/15 workouts logged',
          targetValText: '15 workouts + Cardio required',
        );

      case 'badge_14': // Master Explorer
        final count = activity.distinctExercisesTried.length;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Master Explorer", explore and log sets across 10 different exercise types from the library.',
          actionButtonText: 'Explore Exercises',
          routePath: '/library',
          actionIcon: Icons.travel_explore_rounded,
          progressRatio: (count / 10.0).clamp(0.0, 1.0),
          currentValText: '$count/10 exercises tried',
          targetValText: '10 distinct exercises required',
        );

      case 'badge_15': // 100-Day Legend
        final streak = activity.currentStreakDays;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "100-Day Legend", achieve an extraordinary 100-day active workout streak.',
          actionButtonText: 'Log Daily Workout',
          routePath: '/workout-logging',
          actionIcon: Icons.workspace_premium_rounded,
          progressRatio: (streak / 100.0).clamp(0.0, 1.0),
          currentValText: '$streak/100 days streak',
          targetValText: '100 days streak required',
        );

      case 'badge_16': // God of Iron
        final count = activity.loggedWorkoutsCount;
        final weight = activity.maxWeightLiftedKg;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "God of Iron", unlock all lower tier badges, complete 150 workouts and log a 180kg+ PR lift.',
          actionButtonText: 'Log 180kg PR Lift',
          routePath: '/workout-logging',
          actionIcon: Icons.military_tech_rounded,
          progressRatio: (weight / 180.0).clamp(0.0, 1.0),
          currentValText: '${weight.toStringAsFixed(0)}kg PR / $count workouts',
          targetValText: '180kg PR & 150 workouts required',
        );

      case 'badge_17': // Immortal Titan
        final streak = activity.currentStreakDays;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Immortal Titan", unlock all lower tier badges and maintain an unbroken 365-day streak.',
          actionButtonText: 'Keep Streak Alive',
          routePath: '/workout-logging',
          actionIcon: Icons.local_fire_department_rounded,
          progressRatio: (streak / 365.0).clamp(0.0, 1.0),
          currentValText: '$streak/365 days streak',
          targetValText: '365 days streak required',
        );

      case 'badge_18': // Grandmaster Explorer
        final count = activity.distinctExercisesTried.length;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Grandmaster Explorer", unlock all lower tier badges and log sets in at least 20 distinct exercises.',
          actionButtonText: 'Explore Exercises',
          routePath: '/library',
          actionIcon: Icons.auto_awesome_rounded,
          progressRatio: (count / 20.0).clamp(0.0, 1.0),
          currentValText: '$count/20 exercises tried',
          targetValText: '20 distinct exercises required',
        );

      case 'badge_19': // Gymyzio Legend
        final count = activity.loggedWorkoutsCount;
        return BadgeTaskInfo(
          taskInstructions: 'To unlock "Gymyzio Legend", unlock all 15 lower tier badges and reach 200 total logged workouts.',
          actionButtonText: 'Log Workout Session',
          routePath: '/workout-logging',
          actionIcon: Icons.diamond_rounded,
          progressRatio: (count / 200.0).clamp(0.0, 1.0),
          currentValText: '$count/200 total workouts',
          targetValText: 'All lower badges + 200 workouts required',
        );

      default:
        return const BadgeTaskInfo(
          taskInstructions: 'Complete workout activities to unlock this achievement badge.',
          actionButtonText: 'Log Workout',
          routePath: '/workout-logging',
          actionIcon: Icons.play_arrow_rounded,
          progressRatio: 0.0,
          currentValText: 'Locked',
          targetValText: 'Requirement pending',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(userActivityProvider);
    final streak = activity.currentStreakDays;
    final tr = ref.watch(trProvider);
    const accentColor = AppColors.badgesAccent;

    final unlockedCount = _countUnlockedBadges(activity);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradientOf(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr('achievements_badges'), style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: AppNotificationBell(),
            ),
          ],
        ),
        body: ResponsiveWebWrapper(
          maxWidth: 1050,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak Header Banner
              _buildStreakHeader(streak, activity.loggedWorkoutsCount, tr)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),

              // Month Grid Streak Calendar
              Text(
                tr('streak_calendar'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              InteractiveStreakCalendar(activity: activity, tr: tr)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              // Badge Showcase Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('badge_showcase'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                  ),
                  Text(
                    '$unlockedCount / ${DummyData.badges.length} ${tr('unlocked')}',
                    style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Collapsible Badge Grid Sections grouped by Tier
              _buildTierBadgeSection(
                context: context,
                ref: ref,
                title: tr('low_tier'),
                tier: BadgeTier.low,
                activity: activity,
                initiallyExpanded: false,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              _buildTierBadgeSection(
                context: context,
                ref: ref,
                title: tr('moderate_tier'),
                tier: BadgeTier.moderate,
                activity: activity,
                initiallyExpanded: false,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 250.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              _buildTierBadgeSection(
                context: context,
                ref: ref,
                title: tr('high_tier'),
                tier: BadgeTier.high,
                activity: activity,
                initiallyExpanded: false,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              _buildTierBadgeSection(
                context: context,
                ref: ref,
                title: 'Legendary Tier 👑',
                tier: BadgeTier.legendary,
                activity: activity,
                initiallyExpanded: false,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 350.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 30),
            ],
          ),
        ),
        ),
      ),
    );
  }

  static void showAllBadgesCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 48),
            ),
            const SizedBox(height: 14),
            const Text(
              '🏆 HALL OF FAME MASTER!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFFFFD700),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '🎉 YOU HAVE UNLOCKED ALL TIERS & ALL BADGES!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Incredible dedication! You have completed every single challenge across Low, Moderate, High, and Legendary Tiers in Gymyzio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimaryOf(ctx),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLightOf(ctx),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please wait a bit for brand new badges and upcoming achievements — updated soon! 🚀',
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(ctx),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.fitness_center_rounded, size: 20),
              label: const Text(
                'Keep Crushing It 💪',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countUnlockedBadges(UserActivity activity) {
    return DummyData.badges.where((b) => isBadgeUnlocked(b, activity)).length;
  }

  Widget _buildStreakHeader(int streak, int loggedWorkouts, String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.container),
        boxShadow: AppColors.softGlow(AppColors.primary, opacity: 0.35, blur: 20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak ${tr('days_active')} ($loggedWorkouts Logged)',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  loggedWorkouts == 0
                      ? 'Log your first workout to unlock your first achievement badge!'
                      : 'Keep logging daily workouts to unlock legendary tier badges.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTierBadgeSection({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required BadgeTier tier,
    required UserActivity activity,
    required bool initiallyExpanded,
  }) {
    final tierBadges = DummyData.badges.where((b) => b.tier == tier).toList();
    final unlockedCount = tierBadges.where((b) => isBadgeUnlocked(b, activity)).length;
    final isLegendaryLocked = (tier == BadgeTier.legendary) && !areLowerTiersCompleted(activity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppRadius.container),
        border: Border.all(
          color: isLegendaryLocked
              ? const Color(0xFFFFD700).withValues(alpha: 0.25)
              : tierBadges.first.tierColor.withValues(alpha: 0.3),
        ),
        boxShadow: AppColors.softGlow(
          isLegendaryLocked ? const Color(0xFFFFD700) : tierBadges.first.tierColor,
          opacity: 0.1,
          blur: 10,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isLegendaryLocked ? false : initiallyExpanded,
            iconColor: isLegendaryLocked ? const Color(0xFFFFD700) : tierBadges.first.tierColor,
            collapsedIconColor: isLegendaryLocked ? AppColors.warning : AppColors.textMuted,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isLegendaryLocked ? const Color(0xFFFFD700) : tierBadges.first.tierColor,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softGlow(
                            isLegendaryLocked ? const Color(0xFFFFD700) : tierBadges.first.tierColor,
                            opacity: 0.5,
                            blur: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLegendaryLocked ? 'Legendary Tier 🔒' : title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isLegendaryLocked ? const Color(0xFFFFD700) : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isLegendaryLocked
                        ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: isLegendaryLocked
                        ? Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Text(
                    isLegendaryLocked
                        ? '🔒 LOCKED (${countUnlockedLowerBadges(activity)}/30)'
                        : '$unlockedCount / ${tierBadges.length} Unlocked',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isLegendaryLocked ? const Color(0xFFFFD700) : tierBadges.first.tierColor,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 14.0, bottom: 16.0),
                child: Builder(
                  builder: (ctx) {
                    final screenWidth = MediaQuery.of(ctx).size.width;
                    final crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLegendaryLocked) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFFFD700), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '🔒 LEGENDARY BADGES HIDDEN & LOCKED',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Complete all 30 badges across Low, Moderate & High tiers to reveal and unlock Legendary Badges!',
                                        style: TextStyle(
                                          color: AppColors.textPrimary.withValues(alpha: 0.9),
                                          fontSize: 12.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Prerequisite Progress: ${countUnlockedLowerBadges(activity)} / 30 Badges Completed',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisExtent: 110,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: tierBadges.length,
                          itemBuilder: (context, index) {
                            final badge = tierBadges[index];
                            final isUnlocked = isBadgeUnlocked(badge, activity);

                            return _buildBadgeCard(context, ref, badge, activity, isUnlocked);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, WidgetRef ref, BadgeItem badge, UserActivity activity, bool isUnlocked) {
    final isLegendaryLocked = (badge.tier == BadgeTier.legendary) && !areLowerTiersCompleted(activity);
    final progressLabel = getBadgeProgressLabel(badge, activity, isUnlocked);
    final taskInfo = getBadgeTaskInfo(badge, activity, isUnlocked);

    // If Legendary tier is locked, show a Mystery Locked Badge card
    final displayTitle = isLegendaryLocked ? '??? Mystery Badge' : badge.title;
    final displayIcon = isLegendaryLocked ? Icons.help_outline_rounded : badge.icon;
    final displayProgress = isLegendaryLocked ? 'Locked 🔒' : progressLabel;

    return AppBouncyTap(
      onTap: () {
        if (isLegendaryLocked) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surfaceOf(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFFFD700), size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      '🔒 LEGENDARY TIER LOCKED',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Legendary Badge is strictly locked and hidden! You must unlock all 30 badges across Low, Moderate, and High Tiers before this badge reveals itself.',
                    style: TextStyle(color: AppColors.textPrimaryOf(ctx), fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLightOf(ctx),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prerequisite Progress: ${countUnlockedLowerBadges(activity)} / 30 Badges Completed',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accent),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (countUnlockedLowerBadges(activity) / 30.0).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: AppColors.surfaceOf(ctx),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceOf(ctx),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked ? badge.color.withValues(alpha: 0.15) : AppColors.surfaceLightOf(ctx),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked ? badge.color.withValues(alpha: 0.6) : AppColors.borderOf(ctx),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    badge.icon,
                    color: isUnlocked ? badge.color : AppColors.textMutedOf(ctx),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badge.tierColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badge.tierColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${badge.tierName.toUpperCase()} TIER',
                              style: TextStyle(
                                color: badge.tierColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isUnlocked ? AppColors.accent : AppColors.warning).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUnlocked ? 'UNLOCKED 🎉' : 'LOCKED 🔒',
                              style: TextStyle(
                                color: isUnlocked ? AppColors.accent : AppColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, letterSpacing: -0.3, color: AppColors.textPrimaryOf(ctx)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.description,
                    style: TextStyle(color: AppColors.textSecondaryOf(ctx), fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar & Counter Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLightOf(ctx).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderOf(ctx).withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              taskInfo.currentValText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? AppColors.accent : AppColors.textPrimaryOf(ctx),
                              ),
                            ),
                            Text(
                              taskInfo.targetValText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMutedOf(ctx),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: taskInfo.progressRatio,
                            minHeight: 7,
                            backgroundColor: AppColors.surfaceOf(ctx),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUnlocked ? AppColors.accent : badge.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // How To Unlock Instructions Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badge.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: badge.color.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUnlocked ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                              size: 18,
                              color: isUnlocked ? AppColors.accent : badge.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUnlocked ? 'ACHIEVEMENT COMPLETE' : 'TASK TO UNLOCK THIS BADGE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isUnlocked ? AppColors.accent : badge.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          taskInfo.taskInstructions,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimaryOf(ctx),
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.borderOf(ctx)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryOf(ctx)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnlocked ? AppColors.accent : badge.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ref.read(userActivityProvider.notifier).unlockBadge(badge.id);
                        Navigator.of(ctx).pop();
                        context.push(taskInfo.routePath);
                      },
                      icon: Icon(taskInfo.actionIcon, size: 18),
                      label: Text(
                        taskInfo.actionButtonText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      child: () {
        final cardContent = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [
                      badge.tierColor.withValues(alpha: 0.12),
                      AppColors.surfaceOf(context),
                      badge.tierColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isUnlocked ? badge.tierColor : AppColors.border,
              width: isUnlocked ? 2.0 : 1,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: badge.tierColor.withValues(alpha: 0.30),
                      blurRadius: badge.tier == BadgeTier.legendary ? 16 : 12,
                      spreadRadius: badge.tier == BadgeTier.legendary ? 1.5 : 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Row: Tier Pill Tag + Status Dot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: badge.tierColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badge.tierColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      badge.tierName.toUpperCase(),
                      style: TextStyle(
                        color: badge.tierColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                    size: 15,
                    color: isUnlocked ? badge.tierColor : AppColors.textMuted,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Middle Row: Badge Icon + Details
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? badge.tierColor.withValues(alpha: 0.20)
                          : (isLegendaryLocked
                              ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                              : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(10),
                      border: isUnlocked ? Border.all(color: badge.tierColor.withValues(alpha: 0.4)) : null,
                    ),
                    child: Icon(
                      displayIcon,
                      color: isUnlocked
                          ? badge.tierColor
                          : (isLegendaryLocked ? const Color(0xFFFFD700) : AppColors.textMuted),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : (isLegendaryLocked ? const Color(0xFFFFD700) : AppColors.textSecondary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayProgress,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isUnlocked
                                ? badge.tierColor
                                : (isLegendaryLocked ? const Color(0xFFFFD700) : AppColors.textMuted),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        if (badge.tier == BadgeTier.legendary && isUnlocked) {
          return cardContent
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(duration: 2200.ms, color: Colors.white.withValues(alpha: 0.45));
        }

        return cardContent;
      }(),
    );
  }
}

class BadgeTaskInfo {
  final String taskInstructions;
  final String actionButtonText;
  final String routePath;
  final IconData actionIcon;
  final double progressRatio;
  final String currentValText;
  final String targetValText;

  const BadgeTaskInfo({
    required this.taskInstructions,
    required this.actionButtonText,
    required this.routePath,
    required this.actionIcon,
    required this.progressRatio,
    required this.currentValText,
    required this.targetValText,
  });
}

class InteractiveStreakCalendar extends StatefulWidget {
  final UserActivity activity;
  final String Function(String) tr;

  const InteractiveStreakCalendar({
    super.key,
    required this.activity,
    required this.tr,
  });

  @override
  State<InteractiveStreakCalendar> createState() => _InteractiveStreakCalendarState();
}

class _InteractiveStreakCalendarState extends State<InteractiveStreakCalendar> {
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });
  }

  void _resetToToday() {
    setState(() {
      _focusedDate = DateTime.now();
    });
  }

  void _showDaySummaryBottomSheet(BuildContext context, DateTime date, bool isDone) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);
    final dayNum = date.day;
    final isFutureDate = date.isAfter(DateTime(now.year, now.month, now.day));

    final workoutData = DummyData.calendarWorkoutDetails[dayNum];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(ctx)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFutureDate
                              ? 'Upcoming Date'
                              : (isDone ? 'Workout Session Completed 💪' : 'Rest & Recovery Day 🧘‍♂️'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDone ? AppColors.accent : AppColors.textMutedOf(ctx),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : (isFutureDate ? AppColors.surfaceLightOf(ctx) : AppColors.secondary.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFutureDate ? 'Future Date' : (isDone ? 'COMPLETED' : widget.tr('rest_day')),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDone ? AppColors.accent : (isFutureDate ? AppColors.textMutedOf(ctx) : AppColors.secondary),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: AppColors.borderOf(ctx), height: 28),

              if (isDone && !isFutureDate) ...[
                Text(
                  workoutData != null ? workoutData['title']! : 'Hypertrophy Strength Workout',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  workoutData != null ? workoutData['summary']! : 'Bench Press 80kg x 8 reps, Incline Dumbbell Press, Triceps Pushdown.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondaryOf(ctx), height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatChip(Icons.timer_outlined, workoutData != null ? workoutData['duration']! : '45 mins', AppColors.secondary),
                    const SizedBox(width: 10),
                    _buildStatChip(Icons.local_fire_department_outlined, workoutData != null ? workoutData['calories']! : '320 kcal', Colors.orangeAccent),
                    const SizedBox(width: 10),
                    _buildStatChip(Icons.fitness_center_rounded, '8,400 kg Vol', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DAILY ACHIEVEMENT UNLOCKED',
                              style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayNum % 2 == 0 ? '🏆 100kg PR Milestone Achieved' : '🔥 Streak Milestone Maintained',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(ctx)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isFutureDate) ...[
                Text(
                  'Future Date Log 📅',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(ctx)),
                ),
                const SizedBox(height: 6),
                Text(
                  'This date hasn\'t arrived yet. Keep up your daily workout logging routine when the date comes!',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(ctx), height: 1.4),
                ),
              ] else ...[
                Text(
                  'Rest & Active Recovery Day 🧘‍♂️',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(ctx)),
                ),
                const SizedBox(height: 6),
                Text(
                  'No workout was logged on this date. Rest days allow muscles to recover and prevent overtraining.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(ctx), height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _focusedDate.year == now.year && _focusedDate.month == now.month;

    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingEmptySlots = firstWeekday - 1;
    final totalGridItems = leadingEmptySlots + daysInMonth;

    final monthYearString = DateFormat('MMMM yyyy').format(_focusedDate);
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppRadius.container),
        border: Border.all(color: AppColors.badgesAccent.withValues(alpha: 0.3)),
        boxShadow: AppColors.softGlow(AppColors.badgesAccent, opacity: 0.12, blur: 14),
      ),
      child: Column(
        children: [
          // Calendar Top Bar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Workout Streak Log',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (!isCurrentMonth)
                InkWell(
                  onTap: _resetToToday,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.today_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 5),
                        Text(
                          'Jump to Today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Month/Year Navigation Controls (< Month Year >)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 28),
                tooltip: 'Previous Month',
              ),
              Text(
                monthYearString,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 28),
                tooltip: 'Next Month',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Weekday Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((day) => Text(
                      day,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ))
                .toList(),
          ),

          const Divider(color: AppColors.border, height: 20),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 44,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: totalGridItems,
            itemBuilder: (context, index) {
              if (index < leadingEmptySlots) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - leadingEmptySlots + 1;
              final targetDate = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
              final isToday = now.year == targetDate.year && now.month == targetDate.month && now.day == targetDate.day;

              final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
              
              // Realtime check: check completedDates set or completedDayNumbers for current month
              final isDone = widget.activity.completedDates.contains(dateStr) ||
                  (isCurrentMonth && widget.activity.completedDayNumbers.contains(dayNumber));

              return AppBouncyTap(
                onTap: () => _showDaySummaryBottomSheet(context, targetDate, isDone),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary
                        : (isToday
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceLight),
                    shape: BoxShape.circle,
                    border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                    boxShadow: isDone ? AppColors.softGlow(AppColors.primary, opacity: 0.4, blur: 8) : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: isDone ? Colors.white : AppColors.textSecondary,
                        fontWeight: isDone || isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
