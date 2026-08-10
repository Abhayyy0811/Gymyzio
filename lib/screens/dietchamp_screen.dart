import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/dietchamp_model.dart';
import '../providers/dietchamp_provider.dart';

class DietChampScreen extends ConsumerStatefulWidget {
  const DietChampScreen({super.key});

  @override
  ConsumerState<DietChampScreen> createState() => _DietChampScreenState();
}

class _DietChampScreenState extends ConsumerState<DietChampScreen>
    with SingleTickerProviderStateMixin {
  // App Meals Onboarding State
  late String _selectedPreference;
  late double _selectedWeight;
  late String _selectedGoal;
  final TextEditingController _weightController = TextEditingController();

  late TabController _tabController;

  // Custom Meals Builder Local State
  final List<_CustomMealBuilderSection> _customSections = [];
  final TextEditingController _customPlanTitleController =
      TextEditingController(text: 'My Custom Diet Plan');

  final List<Map<String, String>> _preferenceOptions = [
    {'label': 'Veg', 'icon': '🥦', 'desc': 'Plant-based & Dairy'},
    {'label': 'Non-Veg', 'icon': '🍗', 'desc': 'Eggs, Chicken & Fish'},
    {'label': 'Eggetarian', 'icon': '🍳', 'desc': 'Veg + Whole Eggs'},
    {'label': 'Vegan', 'icon': '🌱', 'desc': '100% Plant-based'},
  ];

  final List<Map<String, String>> _goalOptions = [
    {'label': 'Fat Loss', 'icon': '🔥', 'desc': 'Calorie deficit for lean cuts'},
    {'label': 'Muscle Gain', 'icon': '💪', 'desc': 'Protein surplus for hypertrophy'},
    {'label': 'Maintenance', 'icon': '⚖️', 'desc': 'Balanced maintenance macros'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final state = ref.read(dietChampNotifierProvider);
    _selectedPreference = state.prefs.preference;
    _selectedWeight = state.prefs.weightKg;
    _selectedGoal = state.prefs.goal;
    _weightController.text = _selectedWeight.toStringAsFixed(1);

    // Initialize default meal sections for Custom Builder if empty
    _initDefaultCustomSections();
  }

  void _initDefaultCustomSections() {
    if (_customSections.isEmpty) {
      _customSections.addAll([
        _CustomMealBuilderSection(keyName: 'breakfast', title: 'Breakfast 🍳'),
        _CustomMealBuilderSection(keyName: 'lunch', title: 'Lunch 🥣'),
        _CustomMealBuilderSection(keyName: 'snack', title: 'Evening Snack ☕'),
        _CustomMealBuilderSection(keyName: 'dinner', title: 'Dinner 🥗'),
      ]);
    }
  }

  void _loadExistingCustomPlanForEditing(DietPlan plan) {
    setState(() {
      _customPlanTitleController.text = plan.description;
      _customSections.clear();
      plan.meals.forEach((key, meal) {
        _customSections.add(_CustomMealBuilderSection(
          keyName: key,
          title: meal.title,
          items: List.from(meal.items),
          isConfirmed: true,
        ));
      });
    });
    ref.read(dietChampNotifierProvider.notifier).editCustomPlan();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _tabController.dispose();
    _customPlanTitleController.dispose();
    super.dispose();
  }

  String _getWeightTierLabel(double weight) {
    if (weight < 55.0) return 'W1 (< 55 kg)';
    if (weight <= 70.0) return 'W2 (55 - 70 kg)';
    if (weight <= 85.0) return 'W3 (70 - 85 kg)';
    return 'W4 (> 85 kg)';
  }

  void _saveAppSetup() {
    ref.read(dietChampNotifierProvider.notifier).savePreferences(
          preference: _selectedPreference,
          weightKg: _selectedWeight,
          goal: _selectedGoal,
        );
  }

  void _saveCustomBuildPlan() {
    final Map<String, DietMeal> mealsMap = {};

    for (final sec in _customSections) {
      if (sec.items.isNotEmpty) {
        mealsMap[sec.keyName] = DietMeal(
          title: sec.title,
          items: List.from(sec.items),
        );
      }
    }

    if (mealsMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 food item to your custom meal plan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final customPlan = DietPlan(
      preference: 'Custom',
      weightCategory: 'Self-Customized',
      goal: 'Personalized Goal',
      description: _customPlanTitleController.text.trim().isEmpty
          ? 'Personalized Custom Diet Chart'
          : _customPlanTitleController.text.trim(),
      meals: mealsMap,
    );

    ref.read(dietChampNotifierProvider.notifier).saveCustomPlan(customPlan);
    ref.invalidate(customDietPlanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dietState = ref.watch(dietChampNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'DietChamp',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryOf(context),
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        actions: [
          if (dietState.dietMode != 'none')
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimaryOf(context)),
              tooltip: 'DietChamp Options',
              color: AppColors.surfaceOf(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                if (val == 'switch_mode') {
                  ref.read(dietChampNotifierProvider.notifier).resetMode();
                } else if (val == 'edit_app') {
                  setState(() {
                    _selectedPreference = dietState.prefs.preference;
                    _selectedWeight = dietState.prefs.weightKg;
                    _selectedGoal = dietState.prefs.goal;
                    _weightController.text = _selectedWeight.toStringAsFixed(1);
                  });
                  ref.read(dietChampNotifierProvider.notifier).editPreferences();
                } else if (val == 'edit_custom') {
                  final customPlanAsync = ref.read(customDietPlanProvider);
                  customPlanAsync.whenData((plan) {
                    if (plan != null) {
                      _loadExistingCustomPlanForEditing(plan);
                    }
                  });
                }
              },
              itemBuilder: (ctx) => [
                if (dietState.dietMode == 'app' && dietState.isOnboarded)
                  const PopupMenuItem(
                    value: 'edit_app',
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Edit Preferences ⚙️', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (dietState.dietMode == 'custom' && dietState.hasCustomPlan)
                  const PopupMenuItem(
                    value: 'edit_custom',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: Colors.amber),
                        SizedBox(width: 10),
                        Text('Edit Custom Meals ✏️', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'switch_mode',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Switch Diet Mode 🔄'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildBodyForCurrentMode(context, dietState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyForCurrentMode(BuildContext context, DietChampState dietState) {
    // Mode 1: Selection Screen (App Meals vs Custom Meals)
    if (dietState.dietMode == 'none') {
      return _buildModeSelectionView(context);
    }

    // Mode 2: App Meals Mode
    if (dietState.dietMode == 'app') {
      if (!dietState.isOnboarded) {
        return _buildOnboardingSetupView(context);
      }
      return _buildDashboardView(context, dietState, isCustom: false);
    }

    // Mode 3: Custom Meals Mode
    if (dietState.dietMode == 'custom') {
      if (!dietState.hasCustomPlan) {
        return _buildCustomMealBuilderView(context);
      }
      return _buildDashboardView(context, dietState, isCustom: true);
    }

    return _buildModeSelectionView(context);
  }

  // ==========================================
  // 0. MODE SELECTION SCREEN (App Meals vs Custom Meals)
  // ==========================================
  Widget _buildModeSelectionView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Welcome Banner with Glassmorphism Parallax Depth
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to DietChamp 🥗',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select how you want to manage your diet plan today. Choose between pre-configured smart charts or build your own customized meal plan.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 32),

          Text(
            'Choose Diet Mode:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),

          // Option Card 1: App Meals (Pre-configured)
          AppBouncyTap(
            onTap: () {
              ref.read(dietChampNotifierProvider.notifier).setMode('app');
            },
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🍽️', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'App Meals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryOf(context),
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pre-configured offline diet charts based on your preference (Veg/Non-Veg), weight category & goal.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOf(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 18),

          // Option Card 2: Custom Meals (Self Customization)
          AppBouncyTap(
            onTap: () {
              ref.read(dietChampNotifierProvider.notifier).setMode('custom');
            },
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('✏️', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Meals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryOf(context),
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Build your own diet chart from scratch. Add custom meal sections, sub-meals with macros & track daily completion.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOf(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  // ==========================================
  // 1. APP MEALS ONBOARDING & SETUP VIEW
  // ==========================================
  Widget _buildOnboardingSetupView(BuildContext context) {
    final weightTier = _getWeightTierLabel(_selectedWeight);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Meals Setup 🥗',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get your 100% offline, tailored nutrition chart with real-time meal completion tracking & daily reset.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          // Section 1: Dietary Preference
          Text(
            '1. Dietary Preference',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 82,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _preferenceOptions.length,
            itemBuilder: (context, index) {
              final opt = _preferenceOptions[index];
              final isSelected = _selectedPreference == opt['label'];
              return AppBouncyTap(
                onTap: () {
                  setState(() => _selectedPreference = opt['label']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderOf(context),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10)]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(opt['icon']!, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              opt['label']!,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt['desc']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMutedOf(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section 2: Current Weight & Dynamic Tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. Current Weight (kg)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                  fontFamily: 'Outfit',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Tier: $weightTier',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _selectedWeight.clamp(30.0, 150.0),
                          min: 30.0,
                          max: 150.0,
                          divisions: 240,
                          onChanged: (val) {
                            setState(() {
                              _selectedWeight = double.parse(val.toStringAsFixed(1));
                              _weightController.text = _selectedWeight.toStringAsFixed(1);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 85,
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryOf(context),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          suffixText: 'kg',
                          suffixStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.borderOf(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 30.0 && parsed <= 150.0) {
                            setState(() {
                              _selectedWeight = parsed;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('W1 (<55kg)', style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context))),
                    Text('W2 (55-70kg)', style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context))),
                    Text('W3 (70-85kg)', style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context))),
                    Text('W4 (>85kg)', style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Fitness Goal
          Text(
            '3. Fitness Goal',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: _goalOptions.map((opt) {
              final isSelected = _selectedGoal == opt['label'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppBouncyTap(
                  onTap: () {
                    setState(() => _selectedGoal = opt['label']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderOf(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(opt['icon']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['label']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt['desc']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMutedOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saveAppSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Generate My Diet Plan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. CUSTOM MEAL BUILDER VIEW
  // ==========================================
  Widget _buildCustomMealBuilderView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner with Gradient Parallax Styling
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.secondary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Diet Builder ✏️',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your custom meal sections and sub-meals with exact macros. Confirm each section when ready!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0),

          const SizedBox(height: 22),

          // Plan Title Input
          TextField(
            controller: _customPlanTitleController,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
            ),
            decoration: InputDecoration(
              labelText: 'Plan Name / Title',
              hintText: 'e.g. My Lean Bulk Chart',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.bookmark_border_rounded, color: AppColors.primary),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meal Sections (${_customSections.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                  fontFamily: 'Outfit',
                ),
              ),
              TextButton.icon(
                onPressed: _showAddNewMealSectionDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                label: const Text(
                  'Add Meal Section',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of Meal Builder Sections
          Column(
            children: _customSections.asMap().entries.map((entry) {
              final idx = entry.key;
              final sec = entry.value;
              return _buildCustomSectionCard(context, idx, sec);
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Confirm & Save Custom Diet Plan Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveCustomBuildPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: const Text(
                'Save & Start Tracking My Diet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCustomSectionCard(
    BuildContext context,
    int index,
    _CustomMealBuilderSection sec,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sec.isConfirmed
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.25),
          width: sec.isConfirmed ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      sec.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (sec.isConfirmed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Confirmed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _customSections.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Delete Section',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items inside this section
          if (sec.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text(
                  'No food items added yet. Click "+ Add Sub-Meal Item" below.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMutedOf(context)),
                ),
              ),
            )
          else
            Column(
              children: sec.items.asMap().entries.map((itemEntry) {
                final itemIdx = itemEntry.key;
                final item = itemEntry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLightOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '🔥 ${item.calories} kcal | Protein: ${item.protein}g | Carbs: ${item.carbs}g | Fats: ${item.fats}g',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            sec.items.removeAt(itemIdx);
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // Action Buttons: Add Sub-Meal Item & Confirm Section
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddSubMealItemDialog(sec),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryOf(context),
                    side: BorderSide(color: AppColors.borderOf(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('+ Add Sub-Meal Item', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  if (sec.items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add at least 1 sub-meal item before confirming.'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    sec.isConfirmed = !sec.isConfirmed;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: sec.isConfirmed ? AppColors.primary : AppColors.primary.withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  sec.isConfirmed ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  sec.isConfirmed ? 'Confirmed ✅' : 'Confirm Meal',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  void _showAddNewMealSectionDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceOf(context),
          title: Text(
            'Add Meal Section',
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimaryOf(context)),
            decoration: InputDecoration(
              hintText: 'e.g. Pre-Workout Snack 🍌',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = titleController.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    _customSections.add(_CustomMealBuilderSection(
                      keyName: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      title: txt,
                    ));
                  });
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Add Section',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddSubMealItemDialog(_CustomMealBuilderSection sec) {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final pController = TextEditingController();
    final cController = TextEditingController();
    final fController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Sub-Meal Item to ${sec.title}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryOf(context),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: TextStyle(color: AppColors.textPrimaryOf(context)),
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'e.g. 150g Grilled Chicken Breast',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: calController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(color: AppColors.textPrimaryOf(context)),
                          decoration: InputDecoration(
                            labelText: 'Calories',
                            suffixText: 'kcal',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: pController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          style: TextStyle(color: AppColors.textPrimaryOf(context)),
                          decoration: InputDecoration(
                            labelText: 'Protein',
                            suffixText: 'g',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          style: TextStyle(color: AppColors.textPrimaryOf(context)),
                          decoration: InputDecoration(
                            labelText: 'Carbs',
                            suffixText: 'g',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: fController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          style: TextStyle(color: AppColors.textPrimaryOf(context)),
                          decoration: InputDecoration(
                            labelText: 'Fats',
                            suffixText: 'g',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final cal = num.tryParse(calController.text) ?? 0;
                          final p = num.tryParse(pController.text) ?? 0;
                          final c = num.tryParse(cController.text) ?? 0;
                          final f = num.tryParse(fController.text) ?? 0;

                          if (name.isNotEmpty) {
                            setState(() {
                              sec.items.add(DietMealItem(
                                name: name,
                                calories: cal,
                                protein: p,
                                carbs: c,
                                fats: f,
                              ));
                            });
                            Navigator.pop(dialogContext);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'Add Item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 3. DIET DISPLAY DASHBOARD VIEW (REUSED FOR BOTH APP MEALS & CUSTOM MEALS)
  // ==========================================
  Widget _buildDashboardView(
    BuildContext context,
    DietChampState dietState, {
    required bool isCustom,
  }) {
    final AsyncValue<DietPlan?> asyncPlan =
        isCustom ? ref.watch(customDietPlanProvider) : ref.watch(dietChampPlanProvider);

    return asyncPlan.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load diet plan.',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimaryOf(context)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(isCustom ? customDietPlanProvider : dietChampPlanProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (plan) {
        if (plan == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No custom plan found.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ref.read(dietChampNotifierProvider.notifier).setMode('custom');
                  },
                  child: const Text('Create Custom Plan'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Top Tab Switcher: "Active Plan" vs "Meals Taken"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondaryOf(context),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Outfit',
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_rounded, size: 17),
                          const SizedBox(width: 6),
                          const Text('Active Plan'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt_rounded, size: 17),
                          const SizedBox(width: 6),
                          Text('Meals Taken (${dietState.eatenLogs.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Active Plan (Current pending meals)
                  _buildActivePlanTab(context, dietState, plan),

                  // Tab 2: Meals Taken (History & Consumed Macros Log)
                  _buildMealsTakenTab(context, dietState, plan),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 1: ACTIVE PLAN VIEW
  // ==========================================
  Widget _buildActivePlanTab(BuildContext context, DietChampState dietState, DietPlan plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Header Card
          _buildSummaryCard(context, dietState, plan),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Meal Breakdown',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                  fontFamily: 'Outfit',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Today, ${DateFormat('MMM d').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render Active Meal Cards dynamically for all available meal keys
          ...plan.meals.entries.map((entry) {
            return _buildActiveMealCard(
              context,
              entry.value.title,
              entry.key,
              entry.value,
              dietState,
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MEALS TAKEN (HISTORY & TRACKING)
  // ==========================================
  Widget _buildMealsTakenTab(BuildContext context, DietChampState dietState, DietPlan plan) {
    final logs = dietState.eatenLogs.values.toList();
    logs.sort((a, b) => b.eatenAt.compareTo(a.eatenAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Consumed Macros Progress Overview Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Nutrition Consumed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    if (logs.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(dietChampNotifierProvider.notifier).resetTodayMeals();
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Colors.orangeAccent),
                        label: const Text(
                          'Reset Today',
                          style: TextStyle(fontSize: 12.5, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total Consumed Calories vs Target
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${dietState.totalConsumedCalories}',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Text(
                      ' / ${plan.targetCalories} kcal eaten',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Indicator Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: plan.targetCalories > 0
                        ? (dietState.totalConsumedCalories / plan.targetCalories).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 10,
                    backgroundColor: AppColors.borderOf(context),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Consumed Macros Row with Full Words (Protein, Carbs, Fats)
                Row(
                  children: [
                    Expanded(
                      child: _buildMacroStat('Protein Eaten', '${dietState.totalConsumedProtein.toStringAsFixed(1)}g', Colors.orangeAccent),
                    ),
                    Expanded(
                      child: _buildMacroStat('Carbs Eaten', '${dietState.totalConsumedCarbs.toStringAsFixed(1)}g', Colors.lightBlueAccent),
                    ),
                    Expanded(
                      child: _buildMacroStat('Fats Eaten', '${dietState.totalConsumedFats.toStringAsFixed(1)}g', Colors.pinkAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Eaten Items History (${logs.length})',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 14),

          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_box_outline_blank_rounded, size: 44, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No meals marked as eaten today yet.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check off food items in the "Active Plan" tab to log them here.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMutedOf(context)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final item = logs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLightOf(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.formattedTime,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMutedOf(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '${item.mealCategory} • ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                _buildMacroBadge('${item.calories} kcal', Colors.amber),
                                _buildMacroBadge('Protein: ${item.protein}g', Colors.orangeAccent),
                                _buildMacroBadge('Carbs: ${item.carbs}g', Colors.lightBlueAccent),
                                _buildMacroBadge('Fats: ${item.fats}g', Colors.pinkAccent),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==========================================
  // SUMMARY CARD (TOP DASHBOARD OVERVIEW)
  // ==========================================
  Widget _buildSummaryCard(BuildContext context, DietChampState dietState, DietPlan plan) {
    final remainingCal = (plan.targetCalories - dietState.totalConsumedCalories).clamp(0, plan.targetCalories);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Chips Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  dietState.dietMode == 'custom'
                      ? 'Custom Plan'
                      : '${dietState.prefs.preference} • ${dietState.prefs.weightCategoryLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  dietState.dietMode == 'custom' ? '🎯 Custom Chart' : '🎯 ${dietState.prefs.goal}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Target',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${plan.targetCalories}',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryOf(context),
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'kcal / day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  Text(
                    '$remainingCal kcal',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // Macro Breakdown Bar with Full Words
          Row(
            children: [
              Expanded(
                child: _buildMacroStat('Protein', '${plan.proteinGrams}g', Colors.orangeAccent),
              ),
              Expanded(
                child: _buildMacroStat('Carbs', '${plan.carbsGrams}g', Colors.lightBlueAccent),
              ),
              Expanded(
                child: _buildMacroStat('Fats', '${plan.fatsGrams}g', Colors.pinkAccent),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildMacroStat(String label, String val, Color accentColor) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accentColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ACTIVE MEAL CARD WITH CHECKBOX & HEADER MACROS BUTTON
  // ==========================================
  Widget _buildActiveMealCard(
    BuildContext context,
    String categoryTitle,
    String mealKey,
    DietMeal meal,
    DietChampState dietState,
  ) {
    // Filter un-eaten items for active plan view
    final remainingItems = meal.items
        .where((item) => !dietState.eatenLogs.containsKey(item.id))
        .toList();

    if (remainingItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.task_alt_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '$categoryTitle - All items eaten! 🎉',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondaryOf(context),
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showMacrosDialog(context, categoryTitle, meal),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.analytics_rounded, size: 14),
              label: const Text('Macros 📊', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Title & Header-Level Macros Pop-up Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  categoryTitle,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                    fontFamily: 'Outfit',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total Calories Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${meal.calories} kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Header-Level Macros Button (Top Right of Meal Card)
                  ElevatedButton.icon(
                    onPressed: () => _showMacrosDialog(context, categoryTitle, meal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.analytics_rounded, size: 14),
                    label: const Text(
                      'Macros 📊',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Interactive Item-Level Checkbox List (Only Checkbox clicks mark item as eaten!)
          Column(
            children: remainingItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLightOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Checkbox explicitly triggers item eaten logging
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Checkbox(
                          value: false,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (val) {
                            ref.read(dietChampNotifierProvider.notifier).toggleItemEaten(
                                  mealCategory: categoryTitle,
                                  item: item,
                                );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showSingleItemMacrosDialog(context, categoryTitle, item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.analytics_rounded, size: 13),
                        label: const Text(
                          'Macros 📊',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0);
  }

  // ==========================================
  // SINGLE SUB-MEAL ITEM MACROS POP-UP DIALOG
  // ==========================================
  void _showSingleItemMacrosDialog(BuildContext context, String categoryTitle, DietMealItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Item Macros 📊',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryOf(context),
                                  fontFamily: 'Outfit',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$categoryTitle Section',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppColors.borderOf(context), height: 1),
                  const SizedBox(height: 14),

                  // Individual Macro Breakdown Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLightOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Column(
                      children: [
                        _buildSingleMacroRow(context, 'Calories', '${item.calories} kcal', Colors.amber),
                        const SizedBox(height: 10),
                        _buildSingleMacroRow(context, 'Protein', '${item.protein}g', Colors.orangeAccent),
                        const SizedBox(height: 10),
                        _buildSingleMacroRow(context, 'Carbs', '${item.carbs}g', Colors.lightBlueAccent),
                        const SizedBox(height: 10),
                        _buildSingleMacroRow(context, 'Fats', '${item.fats}g', Colors.pinkAccent),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleMacroRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Outfit',
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PERFECTLY ALIGNED CENTERED POP-UP MACROS DIALOG
  // ==========================================
  void _showMacrosDialog(BuildContext context, String categoryTitle, DietMeal meal) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pie_chart_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$categoryTitle Macros 📊',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryOf(context),
                                  fontFamily: 'Outfit',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded, size: 24),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: AppColors.borderOf(context), height: 1),
                  const SizedBox(height: 16),

                  // Itemized Breakdown List Header
                  Text(
                    'Itemized Macro Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryOf(context),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: meal.items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLightOf(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.borderOf(context),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Name and Calories on top row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimaryOf(context),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${item.calories} kcal',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Full Macro Badges (Protein, Carbs, Fats in FULL words)
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    _buildMacroBadge('Protein: ${item.protein}g', Colors.orangeAccent),
                                    _buildMacroBadge('Carbs: ${item.carbs}g', Colors.lightBlueAccent),
                                    _buildMacroBadge('Fats: ${item.fats}g', Colors.pinkAccent),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: AppColors.borderOf(context), height: 1),
                  const SizedBox(height: 16),

                  // Combined Total Section Summary Badges
                  Text(
                    'Combined Meal Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryOf(context),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTotalMacroColumn('Calories', '${meal.calories} kcal', Colors.amber),
                        _buildTotalMacroColumn('Protein', '${meal.protein}g', Colors.orangeAccent),
                        _buildTotalMacroColumn('Carbs', '${meal.carbs}g', Colors.lightBlueAccent),
                        _buildTotalMacroColumn('Fats', '${meal.fats}g', Colors.pinkAccent),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Close Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTotalMacroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// Helper class for Custom Meal Builder Sections
class _CustomMealBuilderSection {
  final String keyName;
  String title;
  final List<DietMealItem> items;
  bool isConfirmed;

  _CustomMealBuilderSection({
    required this.keyName,
    required this.title,
    List<DietMealItem>? items,
    this.isConfirmed = false,
  }) : items = items ?? [];
}
