import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../models/workout_session.dart';
import '../utils/unit_converter.dart';
import '../utils/body_metrics_calculator.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExercise = ref.watch(progressSelectedExerciseProvider);
    final dateRange = ref.watch(progressDateRangeProvider);
    final tr = ref.watch(trProvider);
    final unitSystem = ref.watch(appUnitSystemProvider);
    final profile = ref.watch(userProfileProvider);

    final completedWorkoutsAsync = ref.watch(completedWorkoutsProvider);
    final bodyWeightLogsAsync = ref.watch(bodyWeightLogsProvider);

    final completedWorkouts = completedWorkoutsAsync.value ?? [];
    final bodyWeightLogs = bodyWeightLogsAsync.value ?? [];
    final userActivity = ref.watch(userActivityProvider);

    final customBmi = ref.watch(customBmiOverrideProvider);
    final customBodyFat = ref.watch(customBodyFatOverrideProvider);

    const accentColor = AppColors.progressAccent;

    // Calculate dynamic BMI from real user profile
    final calculatedBmi = customBmi ??
        (profile.height > 0 && profile.weight > 0
            ? BodyMetricsCalculator.calculateBMI(
                height: profile.height,
                weight: profile.weight,
                unitSystem: profile.unitSystem,
              )
            : 22.8);
    final bmiCategory = BodyMetricsCalculator.getBmiCategory(calculatedBmi);

    // Calculate dynamic Body Fat %
    final calculatedBodyFat = customBodyFat ??
        (calculatedBmi > 0
            ? BodyMetricsCalculator.calculateBodyFat(
                bmi: calculatedBmi,
                age: profile.age > 0 ? profile.age : 24,
                isMale: true,
              )
            : 15.4);
    final bodyFatCategory = BodyMetricsCalculator.getBodyFatCategory(calculatedBodyFat, isMale: true);

    // Extract real exercise names from completed user workouts
    final Set<String> loggedExerciseNames = {};
    for (final w in completedWorkouts) {
      for (final e in w.exercises) {
        if (e.exerciseName.trim().isNotEmpty) {
          loggedExerciseNames.add(e.exerciseName.trim());
        }
      }
    }
    final defaultExercises = ['Bench Press', 'Squat', 'Deadlift', 'Overhead Press', 'Barbell Row'];
    final allExerciseOptions = loggedExerciseNames.isNotEmpty ? loggedExerciseNames.toList() : defaultExercises;
    final activeSelectedExercise = allExerciseOptions.contains(selectedExercise)
        ? selectedExercise
        : allExerciseOptions.first;

    // Real strength points for selected exercise
    final List<double> realExerciseMaxWeights = [];
    for (final workout in completedWorkouts) {
      final match = workout.exercises.firstWhere(
        (e) => e.exerciseName.toLowerCase() == activeSelectedExercise.toLowerCase(),
        orElse: () => WorkoutExercise(exerciseId: '', exerciseName: '', sets: []),
      );
      if (match.sets.isNotEmpty) {
        double maxInSession = 0.0;
        for (final s in match.sets) {
          if (s.weightKg > maxInSession) maxInSession = s.weightKg;
        }
        if (maxInSession > 0) {
          realExerciseMaxWeights.add(maxInSession);
        }
      }
    }

    final convertedChartPoints = realExerciseMaxWeights.isNotEmpty
        ? realExerciseMaxWeights.map((kg) => UnitConverter.convertWeight(kg, unitSystem)).toList()
        : <double>[];

    // Real Body Weight Trend points
    final List<double> realBodyWeightLogs = [];
    for (final log in bodyWeightLogs) {
      if (log.weightKg > 0) {
        realBodyWeightLogs.add(log.weightKg);
      }
    }
    if (realBodyWeightLogs.isEmpty && profile.weight > 0) {
      realBodyWeightLogs.add(profile.weight);
    }
    final convertedBodyWeightPoints = realBodyWeightLogs.map((kg) => UnitConverter.convertWeight(kg, unitSystem)).toList();

    // Dynamic Overall Volume & PR Calculations
    double totalVolumeKg = 0.0;
    double highestWeightLiftedKg = userActivity.maxWeightLiftedKg;
    for (final w in completedWorkouts) {
      for (final e in w.exercises) {
        for (final s in e.sets) {
          totalVolumeKg += (s.reps * s.weightKg);
          if (s.weightKg > highestWeightLiftedKg) {
            highestWeightLiftedKg = s.weightKg;
          }
        }
      }
    }

    final displayTotalVolume = UnitConverter.convertWeight(totalVolumeKg, unitSystem).toStringAsFixed(0);
    final displayHighestPR = UnitConverter.convertWeight(highestWeightLiftedKg, unitSystem).toStringAsFixed(1);
    final totalLoggedCount = completedWorkouts.isNotEmpty ? completedWorkouts.length : userActivity.loggedWorkoutsCount;
    final weightUnitLabel = UnitConverter.weightUnit(unitSystem);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr('progress_analytics'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-Time Lifetime Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.container),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  boxShadow: AppColors.softGlow(AppColors.primary, opacity: 0.12, blur: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickStatItem(
                      label: 'Workouts',
                      value: '$totalLoggedCount',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.primary,
                    ),
                    Container(height: 36, width: 1, color: AppColors.border),
                    _buildQuickStatItem(
                      label: 'Volume',
                      value: '$displayTotalVolume $weightUnitLabel',
                      icon: Icons.graphic_eq_rounded,
                      color: AppColors.secondary,
                    ),
                    Container(height: 36, width: 1, color: AppColors.border),
                    _buildQuickStatItem(
                      label: 'Max PR',
                      value: '$displayHighestPR $weightUnitLabel',
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Exercise Selector Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('strength_pr_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                      boxShadow: AppColors.softGlow(accentColor, opacity: 0.1, blur: 8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeSelectedExercise,
                        dropdownColor: AppColors.surfaceLight,
                        icon: const Icon(Icons.arrow_drop_down, color: accentColor),
                        items: allExerciseOptions.map((exName) {
                          return DropdownMenuItem(
                            value: exName,
                            child: Text(exName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(progressSelectedExerciseProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range Filter Chips (Week / Month / All)
              Row(
                children: ['Week', 'Month', 'All'].map((range) {
                  final isSelected = dateRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(range),
                      selected: isSelected,
                      selectedColor: accentColor,
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(progressDateRangeProvider.notifier).state = range;
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Strength Line Chart Card (Real User Data)
              _buildChartCard(
                title: '$activeSelectedExercise ${tr('weight_progress')} ($weightUnitLabel)',
                accentColor: accentColor,
                chartWidget: convertedChartPoints.isNotEmpty
                    ? SizedBox(
                        height: 200,
                        child: LineChart(
                          _createLineChartData(convertedChartPoints, accentColor),
                        ),
                      )
                    : Container(
                        height: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.show_chart_rounded, color: AppColors.textMuted, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'No workout logs for "$activeSelectedExercise" yet',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Log a workout to build your real-time strength progress curve live!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/workout-logging'),
                              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                              label: const Text('Log Workout Now', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 28),

              // Body Stats Section Header
              Text(
                tr('body_stats'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              const SizedBox(height: 14),

              // Body Weight History Chart
              _buildChartCard(
                title: '${tr('body_weight_trend')} ($weightUnitLabel)',
                accentColor: AppColors.secondary,
                chartWidget: SizedBox(
                  height: 180,
                  child: LineChart(
                    _createLineChartData(convertedBodyWeightPoints, AppColors.secondary),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 20),

              // Column-Wise Stacked Large Body Metric Cards with Edit Buttons
              Column(
                children: [
                  // 1. Body Fat % Card
                  _buildDetailedMetricCard(
                    context: context,
                    ref: ref,
                    title: 'Body Fat Percentage',
                    value: '$calculatedBodyFat%',
                    categoryText: bodyFatCategory,
                    icon: Icons.pie_chart_rounded,
                    accentColor: AppColors.accent,
                    subtext: customBodyFat != null
                        ? 'Custom Override Applied (Tap to Edit or Reset)'
                        : 'Auto-calculated using Deurenberg / Navy Circumference Formula',
                    onEdit: () => _showBodyFatEditModal(context, ref, calculatedBodyFat),
                  ),
                  const SizedBox(height: 14),

                  // 2. BMI Score Card
                  _buildDetailedMetricCard(
                    context: context,
                    ref: ref,
                    title: 'BMI Score (Body Mass Index)',
                    value: '$calculatedBmi',
                    categoryText: bmiCategory,
                    icon: Icons.monitor_weight_rounded,
                    accentColor: AppColors.secondary,
                    subtext: customBmi != null
                        ? 'Custom Override Applied (Tap to Edit or Reset)'
                        : 'Auto-calculated from Height & Weight (${profile.heightFormatted}, ${profile.weightFormatted})',
                    onEdit: () => _showBmiEditModal(context, ref, calculatedBmi),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required Color accentColor,
    required Widget chartWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.container),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        boxShadow: AppColors.softGlow(accentColor, opacity: 0.15, blur: 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.softGlow(accentColor, opacity: 0.6, blur: 8),
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          chartWidget,
        ],
      ),
    );
  }

  LineChartData _createLineChartData(List<double> points, Color color) {
    if (points.isEmpty) {
      return LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [],
      );
    }

    final spots = points.length == 1
        ? [FlSpot(0, points.first), FlSpot(1, points.first)]
        : points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final minY = (minVal - 5).clamp(0.0, 1000.0);
    final maxY = maxVal + 5;
    final maxX = (spots.length - 1).toDouble();

    return LineChartData(
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: _getHorizontalLine,
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              int idx = val.toInt();
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text('Log ${idx + 1}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (val, meta) {
              return Text(
                '${val.round()}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: maxX > 0 ? maxX : 1,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: color,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 5,
              color: color,
              strokeWidth: 2.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  static FlLine _getHorizontalLine(double value) => const FlLine(color: AppColors.border, strokeWidth: 1);

  Widget _buildDetailedMetricCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String value,
    required String categoryText,
    required IconData icon,
    required Color accentColor,
    required String subtext,
    required VoidCallback onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.container),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        boxShadow: AppColors.softGlow(accentColor, opacity: 0.15, blur: 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                ],
              ),
              IconButton(
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(8),
                ),
                icon: Icon(Icons.edit_rounded, color: accentColor, size: 18),
                tooltip: 'Edit & Auto-Calculate',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Score & Category Badge Stack
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  categoryText,
                  style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            subtext,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }

  // --- MODALS FOR BMI AND BODY FAT EDITING ---

  void _showBmiEditModal(BuildContext context, WidgetRef ref, double currentBmi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BmiEditModalContent(currentBmi: currentBmi),
    );
  }

  void _showBodyFatEditModal(BuildContext context, WidgetRef ref, double currentBodyFat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BodyFatEditModalContent(currentBodyFat: currentBodyFat),
    );
  }
}

// Stateful Modal Content for Editing & Calculating BMI
class _BmiEditModalContent extends ConsumerStatefulWidget {
  final double currentBmi;
  const _BmiEditModalContent({required this.currentBmi});

  @override
  ConsumerState<_BmiEditModalContent> createState() => _BmiEditModalContentState();
}

class _BmiEditModalContentState extends ConsumerState<_BmiEditModalContent> {
  late TextEditingController _bmiController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  bool _isManual = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    final unitSystem = profile.unitSystem;

    _bmiController = TextEditingController(text: widget.currentBmi.toString());

    final displayWeight = profile.weight > 0 ? UnitConverter.convertWeight(profile.weight, unitSystem) : (unitSystem == 'Imperial' ? 165.0 : 75.0);
    _weightController = TextEditingController(
      text: displayWeight % 1 == 0 ? displayWeight.toInt().toString() : displayWeight.toStringAsFixed(1),
    );

    final displayHeight = profile.height > 0 ? UnitConverter.convertHeight(profile.height, unitSystem) : (unitSystem == 'Imperial' ? 70.0 : 178.0);
    _heightController = TextEditingController(
      text: displayHeight % 1 == 0 ? displayHeight.toInt().toString() : displayHeight.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _bmiController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double _getCalculatedBmi() {
    if (_isManual) {
      return double.tryParse(_bmiController.text.trim()) ?? widget.currentBmi;
    }
    final unitSystem = ref.read(userProfileProvider).unitSystem;
    final hInput = double.tryParse(_heightController.text.trim()) ?? 178.0;
    final wInput = double.tryParse(_weightController.text.trim()) ?? 75.0;

    double hCm = hInput;
    double wKg = wInput;
    if (unitSystem == 'Imperial') {
      hCm = UnitConverter.inchesToCm(hInput);
      wKg = UnitConverter.lbsToKg(wInput);
    }
    return BodyMetricsCalculator.calculateBMI(height: hCm, weight: wKg, unitSystem: unitSystem);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final unitSystem = ref.watch(userProfileProvider).unitSystem;
    final isOverridden = ref.watch(customBmiOverrideProvider) != null;
    final liveBmi = _getCalculatedBmi();
    final liveCategory = BodyMetricsCalculator.getBmiCategory(liveBmi);

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: AppColors.secondary),
                    SizedBox(width: 10),
                    Text(
                      'BMI Calculator & Formula',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Formula Guide Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📐 How Body Mass Index (BMI) is Calculated:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Formula: BMI = Weight (kg) / [Height (m)]²\n'
                    '• Imperial: BMI = 703 × Weight (lbs) / [Height (in)]²\n'
                    '• Categories:\n'
                    '  - Underweight: < 18.5\n'
                    '  - Normal (Healthy): 18.5 – 24.9\n'
                    '  - Overweight: 25.0 – 29.9\n'
                    '  - Obese: ≥ 30.0',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode Selector Toggle
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Auto-Calculate Details'),
                    selected: !_isManual,
                    selectedColor: AppColors.secondary,
                    backgroundColor: AppColors.surfaceLight,
                    onSelected: (val) => setState(() => _isManual = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Manual BMI Entry'),
                    selected: _isManual,
                    selectedColor: AppColors.secondary,
                    backgroundColor: AppColors.surfaceLight,
                    onSelected: (val) => setState(() => _isManual = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!_isManual) ...[
              // Weight Input
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Weight (${UnitConverter.weightUnit(unitSystem)})',
                  prefixIcon: const Icon(Icons.fitness_center_rounded, color: AppColors.secondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Height Input
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Height (${UnitConverter.heightUnit(unitSystem)})',
                  prefixIcon: const Icon(Icons.height_rounded, color: AppColors.secondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              // Custom BMI Input
              TextField(
                controller: _bmiController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Custom BMI Score',
                  hintText: 'e.g. 23.5',
                  prefixIcon: const Icon(Icons.monitor_weight_rounded, color: AppColors.secondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Live Output Result Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Calculated BMI Result', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('$liveBmi', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(liveCategory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: () {
                if (!_isManual) {
                  final hInput = double.tryParse(_heightController.text.trim()) ?? 178.0;
                  final wInput = double.tryParse(_weightController.text.trim()) ?? 75.0;
                  double hCm = hInput;
                  double wKg = wInput;
                  if (unitSystem == 'Imperial') {
                    hCm = UnitConverter.inchesToCm(hInput);
                    wKg = UnitConverter.lbsToKg(wInput);
                  }
                  ref.read(userProfileProvider.notifier).updateProfile(weight: wKg, height: hCm);
                  ref.read(userProfileServiceProvider).saveUserProfile(ref.read(userProfileProvider));
                  ref.read(customBmiOverrideProvider.notifier).state = null; // Clear override
                } else {
                  ref.read(customBmiOverrideProvider.notifier).state = liveBmi;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('BMI Score updated to $liveBmi ($liveCategory)! ✨'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                !_isManual ? 'Save & Apply to Profile' : 'Save Custom BMI Override',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            if (isOverridden) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  ref.read(customBmiOverrideProvider.notifier).state = null;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('BMI reset to automatic calculation from Profile! 🔄'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: const Text(
                  'Reset to Auto-Calculate from Profile',
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Stateful Modal Content for Editing & Calculating Body Fat %
class _BodyFatEditModalContent extends ConsumerStatefulWidget {
  final double currentBodyFat;
  const _BodyFatEditModalContent({required this.currentBodyFat});

  @override
  ConsumerState<_BodyFatEditModalContent> createState() => _BodyFatEditModalContentState();
}

class _BodyFatEditModalContentState extends ConsumerState<_BodyFatEditModalContent> {
  late TextEditingController _bodyFatController;
  late TextEditingController _waistController;
  late TextEditingController _neckController;
  late TextEditingController _hipController;

  int _selectedMethodIndex = 0; // 0 = Deurenberg, 1 = Navy, 2 = Manual

  @override
  void initState() {
    super.initState();
    final unitSystem = ref.read(userProfileProvider).unitSystem;
    _bodyFatController = TextEditingController(text: widget.currentBodyFat.toString());
    _waistController = TextEditingController(text: unitSystem == 'Imperial' ? '33.5' : '85');
    _neckController = TextEditingController(text: unitSystem == 'Imperial' ? '15.0' : '38');
    _hipController = TextEditingController(text: unitSystem == 'Imperial' ? '37.5' : '95');
  }

  @override
  void dispose() {
    _bodyFatController.dispose();
    _waistController.dispose();
    _neckController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  double _getCalculatedBodyFat() {
    if (_selectedMethodIndex == 2) {
      return double.tryParse(_bodyFatController.text.trim()) ?? widget.currentBodyFat;
    }

    final profile = ref.read(userProfileProvider);
    final currentBmi = ref.read(customBmiOverrideProvider) ??
        (profile.height > 0 && profile.weight > 0
            ? BodyMetricsCalculator.calculateBMI(height: profile.height, weight: profile.weight, unitSystem: profile.unitSystem)
            : 22.8);

    if (_selectedMethodIndex == 0) {
      // Deurenberg Method
      return BodyMetricsCalculator.calculateBodyFat(
        bmi: currentBmi,
        age: profile.age > 0 ? profile.age : 24,
        isMale: true,
      );
    } else {
      // US Navy Method
      final unitSystem = profile.unitSystem;
      double w = double.tryParse(_waistController.text.trim()) ?? (unitSystem == 'Imperial' ? 33.5 : 85.0);
      double n = double.tryParse(_neckController.text.trim()) ?? (unitSystem == 'Imperial' ? 15.0 : 38.0);
      double hip = double.tryParse(_hipController.text.trim()) ?? (unitSystem == 'Imperial' ? 37.5 : 95.0);

      if (unitSystem == 'Imperial') {
        w = UnitConverter.inchesToCm(w);
        n = UnitConverter.inchesToCm(n);
        hip = UnitConverter.inchesToCm(hip);
      }

      final h = profile.height > 0 ? profile.height : 178.0;
      return BodyMetricsCalculator.calculateNavyBodyFat(
        heightCm: h,
        waistCm: w,
        neckCm: n,
        hipCm: hip,
        isMale: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final unitSystem = ref.watch(userProfileProvider).unitSystem;
    final isOverridden = ref.watch(customBodyFatOverrideProvider) != null;
    final liveBfp = _getCalculatedBodyFat();
    final liveCategory = BodyMetricsCalculator.getBodyFatCategory(liveBfp, isMale: true);
    final lengthUnit = UnitConverter.heightUnit(unitSystem);

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppColors.accent),
                    SizedBox(width: 10),
                    Text(
                      'Body Fat % Calculator',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Formula Guide Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧪 Body Fat Calculation Methods & Formulations:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Deurenberg Formula: (1.20 × BMI) + (0.23 × Age) - 16.2\n'
                    '2. US Navy Circumference Method: 86.010 × log10(Waist - Neck) - 70.041 × log10(Height) + 36.76\n'
                    '• ACE Body Fat Categories (Male):\n'
                    '  - Essential Fat: < 6%\n'
                    '  - Athletes: 6% – 13.9%\n'
                    '  - Fitness: 14% – 17.9%\n'
                    '  - Average: 18% – 24.9%\n'
                    '  - Obese / High Fat: ≥ 25%',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Method Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Deurenberg (Auto BMI+Age)'),
                    selected: _selectedMethodIndex == 0,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surfaceLight,
                    onSelected: (val) => setState(() => _selectedMethodIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('US Navy Tape Test'),
                    selected: _selectedMethodIndex == 1,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surfaceLight,
                    onSelected: (val) => setState(() => _selectedMethodIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Manual Entry'),
                    selected: _selectedMethodIndex == 2,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surfaceLight,
                    onSelected: (val) => setState(() => _selectedMethodIndex = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedMethodIndex == 1) ...[
              // Navy Inputs
              TextField(
                controller: _waistController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Waist Circumference ($lengthUnit)',
                  hintText: unitSystem == 'Imperial' ? 'e.g. 33.5' : 'e.g. 85',
                  prefixIcon: const Icon(Icons.square_foot_rounded, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _neckController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Neck Circumference ($lengthUnit)',
                  hintText: unitSystem == 'Imperial' ? 'e.g. 15.0' : 'e.g. 38',
                  prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (_selectedMethodIndex == 2) ...[
              // Direct Entry
              TextField(
                controller: _bodyFatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Custom Body Fat %',
                  hintText: 'e.g. 14.5',
                  prefixIcon: const Icon(Icons.pie_chart_rounded, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Live Output Result Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Calculated Body Fat Result', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('$liveBfp%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(liveCategory, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: () {
                if (_selectedMethodIndex == 0) {
                  ref.read(customBodyFatOverrideProvider.notifier).state = null; // Auto Deurenberg
                } else {
                  ref.read(customBodyFatOverrideProvider.notifier).state = liveBfp;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Body Fat % updated to $liveBfp% ($liveCategory)! ✨'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedMethodIndex == 0 ? 'Use Auto Deurenberg Calculation' : 'Save & Apply Body Fat %',
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            if (isOverridden) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  ref.read(customBodyFatOverrideProvider.notifier).state = null;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Body Fat % reset to automatic calculation from Profile! 🔄'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                },
                child: const Text(
                  'Reset to Auto-Calculate from Profile',
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
