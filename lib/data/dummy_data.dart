import 'package:flutter/material.dart';
import '../models/badge_item.dart';

class DummyData {
  static const int currentStreakDays = 5;

  static const List<Map<String, String>> recentPRs = [
    {'exercise': 'Bench Press', 'record': '60kg x 8 reps', 'date': '2 days ago'},
    {'exercise': 'Barbell Squat', 'record': '100kg x 5 reps', 'date': '4 days ago'},
    {'exercise': 'Deadlift', 'record': '120kg x 3 reps', 'date': '1 week ago'},
  ];

  static final List<BadgeItem> badges = [
    // Low Tier (5 Badges)
    const BadgeItem(
      id: 'badge_1',
      title: 'First Step',
      description: 'Logged your very first workout in Gymyzio',
      icon: Icons.emoji_events,
      requiredStreak: 1,
      color: Color(0xFFFF5E36),
      tier: BadgeTier.low,
      category: 'streak',
    ),
    const BadgeItem(
      id: 'badge_2',
      title: '3-Day Warrior',
      description: 'Maintained a 3-day workout streak',
      icon: Icons.local_fire_department,
      requiredStreak: 3,
      color: Color(0xFF00E5FF),
      tier: BadgeTier.low,
      category: 'streak',
    ),
    const BadgeItem(
      id: 'badge_3',
      title: 'High Five',
      description: 'Hit a 5-day active workout streak!',
      icon: Icons.thumb_up,
      requiredStreak: 5,
      color: Color(0xFF00E676),
      tier: BadgeTier.low,
      category: 'streak',
    ),
    const BadgeItem(
      id: 'badge_4',
      title: 'First 50kg Lift',
      description: 'Successfully completed a 50kg strength lift',
      icon: Icons.fitness_center,
      requiredStreak: 1,
      color: Color(0xFFAB47BC),
      tier: BadgeTier.low,
      category: 'strength',
    ),
    const BadgeItem(
      id: 'badge_5',
      title: 'Curious Explorer',
      description: 'Tried 3 different exercises from the library',
      icon: Icons.explore,
      requiredStreak: 2,
      color: Color(0xFFFFD54F),
      tier: BadgeTier.low,
      category: 'exploration',
    ),

    // Moderate Tier (5 Badges)
    const BadgeItem(
      id: 'badge_6',
      title: '7-Day Champion',
      description: 'Maintained a full 7-day workout streak',
      icon: Icons.workspace_premium,
      requiredStreak: 7,
      color: Color(0xFFFFB74D),
      tier: BadgeTier.moderate,
      category: 'streak',
    ),
    const BadgeItem(
      id: 'badge_7',
      title: 'Iron Titan',
      description: 'Completed 10 total strength sessions',
      icon: Icons.fitness_center,
      requiredStreak: 5,
      color: Color(0xFFFF7043),
      tier: BadgeTier.moderate,
      category: 'strength',
    ),
    const BadgeItem(
      id: 'badge_8',
      title: '5K Runner',
      description: 'Completed your first 5km cardio session',
      icon: Icons.directions_run,
      requiredStreak: 4,
      color: Color(0xFF26C6DA),
      tier: BadgeTier.moderate,
      category: 'cardio',
    ),
    const BadgeItem(
      id: 'badge_9',
      title: 'Century Lifter',
      description: 'Lifted a 100kg milestone on Squat or Deadlift',
      icon: Icons.bolt,
      requiredStreak: 5,
      color: Color(0xFFEC407A),
      tier: BadgeTier.moderate,
      category: 'strength',
    ),
    const BadgeItem(
      id: 'badge_10',
      title: 'Hybrid Athlete',
      description: 'Logged both strength and cardio in a single week',
      icon: Icons.attractions,
      requiredStreak: 3,
      color: Color(0xFF7E57C2),
      tier: BadgeTier.moderate,
      category: 'exploration',
    ),

    // High Tier (5 Badges)
    const BadgeItem(
      id: 'badge_11',
      title: '30-Day Master',
      description: 'Maintained an unbroken 30-day streak',
      icon: Icons.stars_rounded,
      requiredStreak: 30,
      color: Color(0xFFFFD700),
      tier: BadgeTier.high,
      category: 'streak',
    ),
    const BadgeItem(
      id: 'badge_12',
      title: 'Century Club',
      description: 'Logged 100 total workouts',
      icon: Icons.military_tech,
      requiredStreak: 100,
      color: Color(0xFF64FFDA),
      tier: BadgeTier.high,
      category: 'consistency',
    ),
    const BadgeItem(
      id: 'badge_13',
      title: '10K Endurance',
      description: 'Completed a 10km endurance cardio run',
      icon: Icons.directions_run_rounded,
      requiredStreak: 15,
      color: Color(0xFF29B6F6),
      tier: BadgeTier.high,
      category: 'cardio',
    ),
    const BadgeItem(
      id: 'badge_14',
      title: 'Master Explorer',
      description: 'Explored and logged 10 different exercise types',
      icon: Icons.travel_explore,
      requiredStreak: 20,
      color: Color(0xFFFFA726),
      tier: BadgeTier.high,
      category: 'exploration',
    ),
    const BadgeItem(
      id: 'badge_15',
      title: '100-Day Legend',
      description: 'Achieved an extraordinary 100-day active streak',
      icon: Icons.workspace_premium_rounded,
      requiredStreak: 100,
      color: Color(0xFFFF1744),
      tier: BadgeTier.high,
      category: 'streak',
    ),
  ];

  static final Map<int, Map<String, String>> calendarWorkoutDetails = {
    1: {'title': 'Upper Body Hypertrophy', 'summary': 'Bench Press 60kg x 8 reps, Incline Flyes', 'duration': '40 mins', 'calories': '280 kcal'},
    4: {'title': 'Leg Day Strength', 'summary': 'Barbell Squat 100kg x 5 reps, Lunges', 'duration': '50 mins', 'calories': '350 kcal'},
    8: {'title': 'Back & Biceps Power', 'summary': 'Deadlift 120kg x 3 reps, Pull-ups', 'duration': '45 mins', 'calories': '310 kcal'},
    12: {'title': 'Cardio Endurance Run', 'summary': '5km Outdoor Run at 5:00 min/km pace', 'duration': '25 mins', 'calories': '290 kcal'},
    15: {'title': 'Shoulders & Core', 'summary': 'Overhead Press 45kg x 6 reps, Planks', 'duration': '40 mins', 'calories': '260 kcal'},
    21: {'title': 'Push Day Volume', 'summary': 'Dumbbell Incline Press 25kg x 10 reps', 'duration': '45 mins', 'calories': '300 kcal'},
    22: {'title': 'Pull Day Focus', 'summary': 'Lat Pulldowns & Cable Rows 60kg', 'duration': '35 mins', 'calories': '240 kcal'},
    23: {'title': 'HIIT Cardio Sprint', 'summary': '10km Interval Cardio Run', 'duration': '50 mins', 'calories': '520 kcal'},
    24: {'title': 'Heavy Leg Day', 'summary': 'Barbell Squats 100kg x 5 reps & Leg Press', 'duration': '55 mins', 'calories': '410 kcal'},
    25: {'title': 'Chest & Triceps Blast', 'summary': 'Bench Press 60kg x 8 reps & Tricep Dips', 'duration': '50 mins', 'calories': '380 kcal'},
  };

  static final Map<String, List<double>> chartExerciseData = {
    'Bench Press': [50.0, 52.5, 55.0, 57.5, 60.0, 62.5],
    'Barbell Squats': [80.0, 85.0, 90.0, 92.5, 97.5, 100.0],
    'Deadlift': [100.0, 105.0, 110.0, 115.0, 117.5, 120.0],
    'Overhead Press': [35.0, 37.5, 40.0, 40.0, 42.5, 45.0],
  };

  static final List<double> bodyWeightData = [77.5, 77.0, 76.4, 76.0, 75.5, 75.0];
}
