import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_shell_scaffold.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_dashboard_screen.dart';
import '../screens/exercise_library_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/workout_logging_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/gamification_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/switch_account_screen.dart';
import '../screens/dietchamp_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // 1. Splash Screen
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // 2. Onboarding Flow
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // 5. Exercise Detail Screen (Full Screen route outside Shell)
    GoRoute(
      path: '/exercise-detail/:id',
      name: 'exerciseDetail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'ex_1';
        return ExerciseDetailScreen(exerciseId: id);
      },
    ),

    // 6. Workout Logging Screen (Full Screen route outside Shell)
    GoRoute(
      path: '/workout-logging',
      name: 'workoutLogging',
      builder: (context, state) => const WorkoutLoggingScreen(),
    ),

    // 7. Switch Account Screen (Full Screen route outside Shell)
    GoRoute(
      path: '/switch-account',
      name: 'switchAccount',
      builder: (context, state) => const SwitchAccountScreen(),
    ),

    // Main Bottom Navigation Shell Routes (3, 4, 7, 8, 9)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShellScaffold(child: child);
      },
      routes: [
        // 3. Home Dashboard
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeDashboardScreen(),
        ),

        // 4. Exercise Library
        GoRoute(
          path: '/library',
          name: 'library',
          builder: (context, state) => const ExerciseLibraryScreen(),
        ),

        // 7. Progress Screen
        GoRoute(
          path: '/progress',
          name: 'progress',
          builder: (context, state) => const ProgressScreen(),
        ),

        // 8. Gamification / Badges Screen
        GoRoute(
          path: '/badges',
          name: 'badges',
          builder: (context, state) => const GamificationScreen(),
        ),

        // DietChamp Screen
        GoRoute(
          path: '/dietchamp',
          name: 'dietchamp',
          builder: (context, state) => const DietChampScreen(),
        ),

        // 9. Settings Screen
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
