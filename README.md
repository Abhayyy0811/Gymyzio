# Gymyzio: Fitness, Health & Guide App

A mobile application UI prototype (Android + iOS) for workout tracking, exercise discovery, form guidance, progress analytics, and gamified achievements built with Flutter, Riverpod, and GoRouter.

---

## 🌟 Key Features

1. **Splash Screen**: Animated parallax logo & tagline intro with automatic route transition.
2. **Onboarding Flow**:
   - **Language Selection**: English & हिंदी toggle.
   - **Unit System**: Metric (kg/cm) vs Imperial (lbs/in).
   - **Profile Setup**: Form validation for Name, Age, Weight, Height, Fitness Goal, and Experience Level.
3. **Home Dashboard**:
   - Parallax `SliverAppBar` hero header.
   - Active streak counter ("5 Day Streak 🔥").
   - Quick-start session launchers ("Start Strength", "Start Cardio", "Browse Library").
   - Personal Record (PR) tracker card & daily pro tip.
4. **Exercise Library Screen**:
   - Functional search bar with real-time local filtering.
   - Category choice chips (Strength / Cardio / All) + Muscle Group dropdown.
   - 15 dummy exercise items with custom thumbnails, difficulty tags, and bookmark toggles.
   - Scroll-staggered entry animations.
5. **Exercise Detail Screen**:
   - Interactive video player container demo (Play/Pause toggle).
   - Step-by-step numbered exercise instructions.
   - Expandable "Common Mistakes" section (`ExpansionTile`).
   - Riverpod-connected favorite button & "Add to Workout" action with SnackBar confirmation.
6. **Workout Logging Screen**:
   - Active workout exercise list with dynamic set row addition.
   - Stepper controls (`-` / `+`) for weight (kg) and repetitions.
   - Interactive countdown rest timer (60s default) with pause, resume, reset, and circular progress ring.
   - Finish workout celebration dialog.
7. **Progress Screen**:
   - Interactive `fl_chart` line chart with exercise selection dropdown.
   - Date range filter chips (Week / Month / All).
   - Body composition stats section with secondary weight trend chart.
8. **Gamification Screen**:
   - Month-grid active streak calendar.
   - Badge showcase: Grid of 8 achievements (unlocked colored vs locked greyed with lock icons).
9. **Settings Screen**:
   - Live state preview box reflecting real-time Riverpod provider updates.
   - Editable language and unit system switches.
   - Dummy "Export Data" & "Sign Out" navigation actions.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x stable)
- Dart SDK with null-safety
- Android Studio / Xcode / VS Code with Flutter extension installed

### Running the App

1. **Clone or navigate to project directory**:
   ```bash
   cd Gymysio
   ```

2. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run application**:
   - **Chrome / Web**:
     ```bash
     flutter run -d chrome
     ```
   - **Android Device / Emulator**:
     ```bash
     flutter run -d android
     ```
   - **iOS Simulator**:
     ```bash
     flutter run -d iphone
     ```
   - **Windows Desktop**:
     ```bash
     flutter run -d windows
     ```

---

## 🏗️ Architecture & Project Structure

```
lib/
├── data/
│   ├── dummy_data.dart           # PRs, streak info, chart data & badge definitions
│   └── dummy_exercises.dart      # 15 detailed exercise records
├── models/
│   ├── badge_item.dart           # Achievement badge data model
│   ├── exercise.dart             # Exercise definition model
│   ├── user_profile.dart         # User settings state model
│   └── workout_session.dart      # Active workout set & exercise models
├── providers/
│   └── app_state_providers.dart  # Riverpod StateNotifiers & StateProviders
├── router/
│   └── app_router.dart           # GoRouter config with 9 named routes & ShellRoute
├── screens/
│   ├── splash_screen.dart        # Screen 1
│   ├── onboarding_screen.dart    # Screen 2
│   ├── home_dashboard_screen.dart# Screen 3
│   ├── exercise_library_screen.dart # Screen 4
│   ├── exercise_detail_screen.dart  # Screen 5
│   ├── workout_logging_screen.dart # Screen 6
│   ├── progress_screen.dart      # Screen 7
│   ├── gamification_screen.dart  # Screen 8
│   └── settings_screen.dart      # Screen 9
├── theme/
│   └── app_theme.dart            # Custom dark color palette, Google Fonts, & AppBouncyTap
├── widgets/
│   └── main_shell_scaffold.dart  # Bottom navigation shell scaffold
└── main.dart                     # App entry point
```

---

## 🧪 Dependencies

- `flutter_riverpod`: State management
- `go_router`: Declarative routing with shell navigation
- `google_fonts`: Typography (`Outfit`)
- `fl_chart`: Interactive charts
- `flutter_animate`: Micro-animations & scroll stagger
- `intl`: Date & number formatting
