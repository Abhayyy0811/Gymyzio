import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state_providers.dart';
import '../data/dummy_data.dart';
import '../models/badge_item.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  static bool isBadgeUnlocked(BadgeItem badge, UserActivity activity) {
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
      default:
        return false;
    }
  }

  static String getBadgeProgressLabel(BadgeItem badge, UserActivity activity, bool isUnlocked) {
    if (isUnlocked) return 'Unlocked 🎉';
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
      default:
        return 'Locked';
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
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr('achievements_badges'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        ),
        body: SingleChildScrollView(
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
              _buildStreakCalendar(context, activity, tr)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 28),

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
                initiallyExpanded: true,
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
                initiallyExpanded: true,
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

              const SizedBox(height: 30),
            ],
          ),
        ),
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

  Widget _buildStreakCalendar(BuildContext context, UserActivity activity, String Function(String) tr) {
    final completedDays = activity.completedDayNumbers;
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayDayNum = DateTime.now().day;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.container),
        border: Border.all(color: AppColors.badgesAccent.withValues(alpha: 0.3)),
        boxShadow: AppColors.softGlow(AppColors.badgesAccent, opacity: 0.12, blur: 14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((day) => Text(day, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)))
                .toList(),
          ),
          const Divider(color: AppColors.border, height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              final dayNumber = index + 1;
              final isDone = completedDays.contains(dayNumber);
              final isToday = dayNumber == todayDayNum;

              return AppBouncyTap(
                onTap: () => _showDaySummaryBottomSheet(context, dayNumber, isDone, tr),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceLight,
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

  void _showDaySummaryBottomSheet(BuildContext context, int dayNumber, bool isDone, String Function(String) tr) {
    final workoutData = DummyData.calendarWorkoutDetails[dayNumber];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  Row(
                    children: [
                      Icon(
                        isDone ? Icons.check_circle_rounded : Icons.nightlife_rounded,
                        color: isDone ? AppColors.accent : AppColors.secondary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Day $dayNumber of Month',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isDone ? 'Completed' : tr('rest_day'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 28),

              if (isDone) ...[
                Text(
                  workoutData != null ? workoutData['title']! : 'Logged Workout Session',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  workoutData != null ? workoutData['summary']! : 'Completed active workout session successfully.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatChip(Icons.timer_outlined, workoutData != null ? workoutData['duration']! : '35m', AppColors.secondary),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.local_fire_department_outlined, workoutData != null ? workoutData['calories']! : '240 kcal', Colors.orangeAccent),
                  ],
                ),
              ] else ...[
                const Text(
                  'Rest & Active Recovery Day 🧘‍♂️',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No workout logged on this date. Rest is critical for muscle repair and peak performance.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.container),
        border: Border.all(color: tierBadges.first.tierColor.withValues(alpha: 0.3)),
        boxShadow: AppColors.softGlow(tierBadges.first.tierColor, opacity: 0.1, blur: 10),
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          iconColor: tierBadges.first.tierColor,
          collapsedIconColor: AppColors.textMuted,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: tierBadges.first.tierColor,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.softGlow(tierBadges.first.tierColor, opacity: 0.5, blur: 6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlockedCount / ${tierBadges.length} Unlocked',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tierBadges.first.tierColor,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14.0, right: 14.0, bottom: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: tierBadges.length,
                itemBuilder: (context, index) {
                  final badge = tierBadges[index];
                  final isUnlocked = isBadgeUnlocked(badge, activity);

                  return _buildBadgeCard(context, badge, activity, isUnlocked);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildBadgeCard(BuildContext context, BadgeItem badge, UserActivity activity, bool isUnlocked) {
    final progressLabel = getBadgeProgressLabel(badge, activity, isUnlocked);

    return AppBouncyTap(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(badge.icon, color: isUnlocked ? badge.color : AppColors.textMuted, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(badge.title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.description, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge.tierColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badge.tierColor),
                      ),
                      child: Text(
                        '${badge.tierName} Tier',
                        style: TextStyle(color: badge.tierColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isUnlocked ? 'STATUS: UNLOCKED 🎉' : 'PROGRESS: $progressLabel',
                        style: TextStyle(
                          color: isUnlocked ? AppColors.accent : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isUnlocked ? badge.color : AppColors.border,
            width: isUnlocked ? 1.5 : 1,
          ),
          boxShadow: isUnlocked ? AppColors.softGlow(badge.color, opacity: 0.08, blur: 8) : null,
        ),
        child: Stack(
          children: [
            // Colored Tier Tag Chip (Top-Right)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badge.tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badge.tierColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  badge.tierName,
                  style: TextStyle(
                    color: badge.tierColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Card Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUnlocked ? badge.color.withValues(alpha: 0.2) : AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        badge.icon,
                        color: isUnlocked ? badge.color : AppColors.textMuted,
                        size: 28,
                      ),
                    ),
                    if (!isUnlocked)
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.lock, size: 10, color: Colors.white70),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  badge.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  progressLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: isUnlocked ? badge.color : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
