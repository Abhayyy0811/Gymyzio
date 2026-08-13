import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../widgets/password_field.dart';
import '../widgets/shine_button.dart';
import '../widgets/shake_widget.dart';
import '../widgets/responsive_web_wrapper.dart';
import '../services/account_registry_service.dart';
import '../utils/phone_utils.dart';
import '../utils/username_utils.dart';
import '../utils/unit_converter.dart';
import '../services/email_otp_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form State for Onboarding Profile Step
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;

  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();
  final _heightFocusNode = FocusNode();
  final _heightFeetFocusNode = FocusNode();
  final _heightInchesFocusNode = FocusNode();
  
  String? _selectedGoal;
  String? _selectedExperience;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name != 'Athlete' ? profile.name : '');
    _ageController = TextEditingController(text: profile.age > 0 ? profile.age.toString() : '');

    if (profile.weight > 0) {
      final displayWeight = UnitConverter.convertWeight(profile.weight, profile.unitSystem);
      _weightController = TextEditingController(
        text: displayWeight % 1 == 0 ? displayWeight.toInt().toString() : displayWeight.toStringAsFixed(1),
      );
    } else {
      _weightController = TextEditingController(text: '');
    }

    if (profile.height > 0) {
      final displayHeightCm = profile.height;
      _heightController = TextEditingController(
        text: displayHeightCm % 1 == 0 ? displayHeightCm.toInt().toString() : displayHeightCm.toStringAsFixed(1),
      );
      final ftIn = UnitConverter.cmToFeetInches(displayHeightCm);
      _heightFeetController = TextEditingController(text: ftIn.feet.toString());
      _heightInchesController = TextEditingController(
        text: ftIn.inches % 1 == 0 ? ftIn.inches.toInt().toString() : ftIn.inches.toStringAsFixed(1),
      );
    } else {
      _heightController = TextEditingController(text: '');
      _heightFeetController = TextEditingController(text: '');
      _heightInchesController = TextEditingController(text: '');
    }

    _selectedGoal = (profile.goal.isNotEmpty && profile.goal != 'Strength') ? profile.goal : null;
    _selectedExperience = (profile.experienceLevel.isNotEmpty && profile.experienceLevel != 'Intermediate') ? profile.experienceLevel : null;

    // Auto-resume onboarding step for authenticated users with incomplete profiles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentProfile = ref.read(userProfileProvider);
      if (currentUser != null && !currentProfile.isFullyCompleted) {
        if (_currentPage == 0) {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    _heightFeetFocusNode.dispose();
    _heightInchesFocusNode.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 1) { // Cannot go back to page 0 once authenticated
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// System and UI back button handler for incomplete profiles
  Future<bool> _handleOnboardingBack() async {
    if (_currentPage > 1) {
      _previousPage();
      return false;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    final profile = ref.read(userProfileProvider);
    if (currentUser != null && !profile.isFullyCompleted) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Incomplete Profile Setup'),
          content: const Text(
            'Your account registration is not complete. If you exit now, you will be signed out of your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continue Setup'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out & Exit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (shouldExit == true) {
        await ref.read(userProfileServiceProvider).deleteUserProfile(currentUser.uid);
        await ref.read(authServiceProvider).signOut();
        if (mounted) {
          setState(() {
            _currentPage = 0;
          });
        }
      }
      return false;
    }
    return true;
  }

  /// Centralized Auth Success handler
  Future<void> _handleAuthSuccess(User user) async {
    try {
      final profileService = ref.read(userProfileServiceProvider);
      final result = await profileService.fetchOrInitUserProfile(user);

      // Update Riverpod user profile state
      ref.read(userProfileProvider.notifier).setProfile(result.profile);
      ref.read(isNewUserProvider.notifier).state = !result.profile.isFullyCompleted;

      if (!mounted) return;

      if (!result.profile.isFullyCompleted) {
        final autoName = user.displayName ?? result.profile.name;
        if (autoName.isNotEmpty && autoName != 'Athlete') {
          _nameController.text = autoName;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.displayName ?? user.email ?? "Athlete"}! Let\'s set up your profile 🔥'),
            backgroundColor: AppColors.accent,
          ),
        );
        // Advance to Onboarding setup steps (Language select)
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Save account to local device registry ONLY when fully completed
        String method = 'email';
        if (user.providerData.isNotEmpty) {
          final p = user.providerData.first.providerId;
          if (p.contains('google')) {
            method = 'google';
          } else if (p.contains('phone')) {
            method = 'phone';
          }
        } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          method = 'phone';
        }

        await ref.read(accountRegistryServiceProvider).saveOrUpdateAccount(
          SavedAccount(
            uid: user.uid,
            displayName: user.displayName ?? result.profile.name,
            identifier: user.email ?? user.phoneNumber ?? result.profile.email ?? 'Athlete',
            photoUrl: user.photoURL,
            signInMethod: method,
            lastUsedAt: DateTime.now(),
          ),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${result.profile.name}! 👋'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Returning user -> skip onboarding straight to Home Dashboard
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing profile: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Submit Onboarding Profile Data
  void _submitProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final currentUser = ref.read(currentUserProvider);
      final currentProfile = ref.read(userProfileProvider);

      final rawWeightInput = double.tryParse(_weightController.text.trim()) ?? 0.0;
      double weightKg = 0.0;
      if (currentProfile.unitSystem == 'Imperial') {
        weightKg = UnitConverter.lbsToKg(rawWeightInput);
      } else {
        weightKg = rawWeightInput;
      }
      if (weightKg <= 0) weightKg = currentProfile.weight;

      double heightCm = 0.0;
      if (currentProfile.unitSystem == 'Imperial') {
        final ft = int.tryParse(_heightFeetController.text.trim()) ?? 0;
        final inch = double.tryParse(_heightInchesController.text.trim()) ?? 0.0;
        heightCm = UnitConverter.feetInchesToCm(ft, inch);
      } else {
        heightCm = double.tryParse(_heightController.text.trim()) ?? 0.0;
      }
      if (heightCm <= 0) heightCm = currentProfile.height;

      final updatedProfile = currentProfile.copyWith(
        uid: currentUser?.uid ?? currentProfile.uid,
        email: (currentUser?.email != null && currentUser!.email!.isNotEmpty)
            ? currentUser.email
            : currentProfile.email,
        phoneNumber: (currentProfile.phoneNumber != null && currentProfile.phoneNumber!.isNotEmpty)
            ? currentProfile.phoneNumber
            : (currentUser?.phoneNumber != null && currentUser!.phoneNumber!.isNotEmpty
                ? normalizePhoneNumber(currentUser.phoneNumber!)
                : null),
        usernameDisplay: currentProfile.usernameDisplay,
        usernameLowercase: currentProfile.usernameLowercase,
        language: currentProfile.language,
        unitSystem: currentProfile.unitSystem,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : currentProfile.name,
        age: int.tryParse(_ageController.text.trim()) ?? currentProfile.age,
        weight: weightKg,
        height: heightCm,
        goal: _selectedGoal ?? 'Strength',
        experienceLevel: _selectedExperience ?? 'Intermediate',
        isProfileComplete: true,
      );

      // Save to Riverpod
      ref.read(userProfileProvider.notifier).setProfile(updatedProfile);

      // Save to Firestore
      await ref.read(userProfileServiceProvider).saveUserProfile(updatedProfile);

      // Save to local device registry ONLY NOW that profile is fully complete
      if (currentUser != null && updatedProfile.isFullyCompleted) {
        String method = 'email';
        if (currentUser.providerData.isNotEmpty) {
          final p = currentUser.providerData.first.providerId;
          if (p.contains('google')) {
            method = 'google';
          } else if (p.contains('phone')) {
            method = 'phone';
          }
        } else if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
          method = 'phone';
        }

        await ref.read(accountRegistryServiceProvider).saveOrUpdateAccount(
          SavedAccount(
            uid: currentUser.uid,
            displayName: updatedProfile.name,
            identifier: currentUser.email ?? currentUser.phoneNumber ?? updatedProfile.email ?? 'Athlete',
            photoUrl: currentUser.photoURL,
            signInMethod: method,
            lastUsedAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete! Welcome to Gymyzio 🔥'),
          backgroundColor: AppColors.primary,
        ),
      );

      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleOnboardingBack();
        }
      },
      child: Theme(
        data: AppTheme.lightTheme,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: ResponsiveWebWrapper(
                maxWidth: 750,
                child: Column(
                  children: [
                    // Top Navigation & Page Indicator (Only show for pages 1, 2, 3)
                    if (_currentPage > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentPage >= 1)
                              AppBouncyTap(
                                onTap: _handleOnboardingBack,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                                ),
                              )
                            else
                              const SizedBox(width: 36),
                    
                    // Dot Indicators for Steps 1, 2, 3
                    Row(
                      children: List.generate(3, (index) {
                        final isActive = (index + 1) == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isActive ? 24 : 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(width: 36),
                  ],
                ),
              ),

                // Page View Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce auth & steps
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildMultiMethodSignInPage(),
                      _buildLanguagePage(profile),
                      _buildUnitPage(profile),
                      _buildProfileFormPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }

  // Step 0: Multi-Method Sign In Screen (Renders Welcome Login Card directly)
  Widget _buildMultiMethodSignInPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: _EmailAuthCard(
          onSuccess: _handleAuthSuccess,
          onPhoneSignIn: () => _showPhoneAuthBottomSheet(context),
        ),
      ),
    );
  }

  // Phone Auth Bottom Sheet Modal
  void _showPhoneAuthBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PhoneAuthModal(
        onSuccess: (user) async {
          Navigator.pop(ctx);
          await _handleAuthSuccess(user);
        },
      ),
    );
  }

  // Step 1: Language Selection
  Widget _buildLanguagePage(UserProfile profile) {
    final currentLang = profile.language;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.language_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Choose Language',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Select your preferred app display language.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          _buildSelectableCard(
            title: 'English',
            subtitle: 'Default language',
            isSelected: currentLang == 'English',
            icon: Icons.translate,
            onTap: () {
              ref.read(userProfileProvider.notifier).setLanguage('English');
            },
          ),
          const SizedBox(height: 16),

          _buildSelectableCard(
            title: 'हिंदी (Hindi)',
            subtitle: 'हिन्दी भाषा चुनें',
            isSelected: currentLang == 'हिंदी',
            icon: Icons.g_translate,
            onTap: () {
              ref.read(userProfileProvider.notifier).setLanguage('हिंदी');
            },
          ),

          const SizedBox(height: 40),
          ShineButton(
            onTap: _nextPage,
            gradient: AppColors.primaryGradient,
            glowColor: AppColors.primaryGlow,
            child: const Center(
              child: Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Unit System Selection
  Widget _buildUnitPage(UserProfile profile) {
    final currentUnit = profile.unitSystem;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.straighten_rounded, size: 64, color: AppColors.secondary),
          const SizedBox(height: 24),
          Text(
            'Select Unit System',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Preferred system for weight and height tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          _buildSelectableCard(
            title: 'Metric System',
            subtitle: 'Kilograms (kg) & Centimeters (cm)',
            isSelected: currentUnit == 'Metric',
            icon: Icons.scale_rounded,
            onTap: () {
              ref.read(userProfileProvider.notifier).setUnitSystem('Metric');
            },
          ),
          const SizedBox(height: 16),

          _buildSelectableCard(
            title: 'Imperial System',
            subtitle: 'Pounds (lbs) & Inches (in)',
            isSelected: currentUnit == 'Imperial',
            icon: Icons.monitor_weight_outlined,
            onTap: () {
              ref.read(userProfileProvider.notifier).setUnitSystem('Imperial');
            },
          ),

          const SizedBox(height: 40),
          ShineButton(
            onTap: _nextPage,
            gradient: AppColors.primaryGradient,
            glowColor: AppColors.primaryGlow,
            child: const Center(
              child: Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Profile Setup Form
  Widget _buildProfileFormPage() {
    final currentProfile = ref.watch(userProfileProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final detectedName = currentUser?.displayName ?? (currentProfile.name != 'Athlete' ? currentProfile.name : '');
    if (_nameController.text.trim().isEmpty && detectedName.isNotEmpty) {
      _nameController.text = toTitleCase(detectedName);
    }

    final currentUnit = currentProfile.unitSystem;
    final weightUnitLabel = currentUnit == 'Imperial' ? 'lbs' : 'kg';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderOf(context), width: 1),
            boxShadow: AppColors.softGlow(AppColors.primary, opacity: 0.15, blur: 24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Graphic Icon Area
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 2),
                      boxShadow: AppColors.softGlow(AppColors.accent, opacity: 0.25, blur: 16),
                    ),
                    child: const Icon(
                      Icons.person_pin_rounded,
                      color: AppColors.accent,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Fitness Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Customize your targets and body metrics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Full Name Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Name',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _ageFocusNode.requestFocus(),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        TitleCaseTextInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Age Stepper Field (Column-wise)
                _buildStepperField(
                  controller: _ageController,
                  focusNode: _ageFocusNode,
                  label: 'Age',
                  hintText: 'Enter your age (e.g. 24)',
                  suffix: 'years',
                  icon: Icons.cake_outlined,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _weightFocusNode.requestFocus(),
                  onDecrement: () {
                    final curr = int.tryParse(_ageController.text.trim()) ?? 0;
                    if (curr > 0) {
                      _ageController.text = (curr - 1).toString();
                    }
                  },
                  onIncrement: () {
                    final curr = int.tryParse(_ageController.text.trim()) ?? 0;
                    _ageController.text = (curr + 1).toString();
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your age';
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) return 'Enter a valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Weight Stepper Field (Column-wise)
                _buildStepperField(
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  label: 'Weight ($weightUnitLabel)',
                  hintText: 'Enter your weight (e.g. 75 $weightUnitLabel)',
                  suffix: weightUnitLabel,
                  isDecimal: true,
                  icon: Icons.fitness_center_rounded,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => currentUnit == 'Imperial'
                      ? _heightFeetFocusNode.requestFocus()
                      : _heightFocusNode.requestFocus(),
                  onDecrement: () {
                    final curr = double.tryParse(_weightController.text.trim()) ?? 0.0;
                    if (curr > 0) {
                      final updated = curr - 1.0;
                      _weightController.text = updated % 1 == 0 ? updated.toInt().toString() : updated.toString();
                    }
                  },
                  onIncrement: () {
                    final curr = double.tryParse(_weightController.text.trim()) ?? 0.0;
                    final updated = curr + 1.0;
                    _weightController.text = updated % 1 == 0 ? updated.toInt().toString() : updated.toString();
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your weight';
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) return 'Enter a valid weight';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Height Stepper Field (Imperial Dual Feet/Inches vs Metric Single CM)
                if (currentUnit == 'Imperial') ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildStepperField(
                          controller: _heightFeetController,
                          focusNode: _heightFeetFocusNode,
                          label: 'Height (ft)',
                          hintText: 'e.g. 5',
                          suffix: 'ft',
                          icon: Icons.height_rounded,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _heightInchesFocusNode.requestFocus(),
                          onDecrement: () {
                            final curr = int.tryParse(_heightFeetController.text.trim()) ?? 0;
                            if (curr > 0) {
                              _heightFeetController.text = (curr - 1).toString();
                            }
                          },
                          onIncrement: () {
                            final curr = int.tryParse(_heightFeetController.text.trim()) ?? 0;
                            _heightFeetController.text = (curr + 1).toString();
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Req. ft';
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null || parsed <= 0) return 'Invalid ft';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStepperField(
                          controller: _heightInchesController,
                          focusNode: _heightInchesFocusNode,
                          label: 'Inches (in)',
                          hintText: 'e.g. 8',
                          suffix: 'in',
                          isDecimal: true,
                          icon: Icons.height_rounded,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitProfile(),
                          onDecrement: () {
                            final curr = double.tryParse(_heightInchesController.text.trim()) ?? 0.0;
                            if (curr > 0) {
                              final updated = curr - 1.0;
                              _heightInchesController.text = updated % 1 == 0 ? updated.toInt().toString() : updated.toString();
                            }
                          },
                          onIncrement: () {
                            final curr = double.tryParse(_heightInchesController.text.trim()) ?? 0.0;
                            if (curr < 11.9) {
                              final updated = curr + 1.0;
                              _heightInchesController.text = updated % 1 == 0 ? updated.toInt().toString() : updated.toString();
                            }
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Req. in';
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed < 0 || parsed >= 12) return '0-11 in';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildStepperField(
                    controller: _heightController,
                    focusNode: _heightFocusNode,
                    label: 'Height (cm)',
                    hintText: 'Enter your height (e.g. 178 cm)',
                    suffix: 'cm',
                    isDecimal: true,
                    icon: Icons.height_rounded,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitProfile(),
                    onDecrement: () {
                      final curr = double.tryParse(_heightController.text.trim()) ?? 0.0;
                      if (curr > 0) {
                        final updated = curr - 1.0;
                        _heightController.text = updated % 1 == 0 ? updated.toInt().toString() : updated.toString();
                      }
                    },
                    onIncrement: () {
                      final curr = double.tryParse(_heightController.text.trim()) ?? 0.0;
                      final updated = curr + 1.0;
                      _heightController.text = updated % 1 == 0 ? updated.toInt().toString() : updated.toString();
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your height';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'Enter a valid height';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // 5. Primary Fitness Goal Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Fitness Goal',
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGoal,
                      hint: Text('Select Primary Fitness Goal', style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14)),
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLightOf(context),
                        prefixIcon: const Icon(Icons.sports_score_rounded, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderOf(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                        ),
                      ),
                      dropdownColor: AppColors.surfaceOf(context),
                      items: ['Strength', 'Cardio', 'Both'].map((goal) {
                        return DropdownMenuItem(value: goal, child: Text(goal, style: TextStyle(color: AppColors.textPrimaryOf(context))));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGoal = val);
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Please select a fitness goal' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Experience Level Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Experience Level',
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExperience,
                      hint: Text('Select Experience Level', style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14)),
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLightOf(context),
                        prefixIcon: const Icon(Icons.stars_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderOf(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                        ),
                      ),
                      dropdownColor: AppColors.surfaceOf(context),
                      items: ['Beginner', 'Intermediate', 'Advanced'].map((exp) {
                        return DropdownMenuItem(value: exp, child: Text(exp, style: TextStyle(color: AppColors.textPrimaryOf(context))));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedExperience = val);
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Please select experience level' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 7. Get Started Action Button
                ShineButton(
                  onTap: _submitProfile,
                  gradient: AppColors.primaryGradient,
                  glowColor: AppColors.primaryGlow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData icon,
    required TextInputAction textInputAction,
    required ValueChanged<String>? onFieldSubmitted,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required String? Function(String?) validator,
    String? suffix,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        FormField<String>(
          initialValue: controller.text,
          validator: (_) => validator(controller.text),
          builder: (formFieldState) {
            final hasError = formFieldState.hasError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLightOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasError ? Colors.redAccent : AppColors.borderOf(context),
                      width: hasError ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Minus (-) Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onDecrement();
                            formFieldState.didChange(controller.text);
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: AppColors.borderOf(context).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 10),
                      Icon(icon, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      // Editable Number Input Field
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: isDecimal
                              ? const TextInputType.numberWithOptions(decimal: true)
                              : TextInputType.number,
                          textInputAction: textInputAction,
                          onSubmitted: onFieldSubmitted,
                          onChanged: (val) {
                            formFieldState.didChange(val);
                          },
                          style: TextStyle(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                            suffixText: suffix != null ? ' $suffix' : null,
                            suffixStyle: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                      // Plus (+) Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onIncrement();
                            formFieldState.didChange(controller.text);
                          },
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      formFieldState.errorText!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectableCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AppBouncyTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26),
          ],
        ),
      ),
    );
  }
}

/// Phone Auth Bottom Sheet Widget
class _PhoneAuthModal extends ConsumerStatefulWidget {
  final Function(User user) onSuccess;

  const _PhoneAuthModal({required this.onSuccess});

  @override
  ConsumerState<_PhoneAuthModal> createState() => _PhoneAuthModalState();
}

class _PhoneAuthModalState extends ConsumerState<_PhoneAuthModal> {
  final _phoneController = TextEditingController(text: '+1 ');
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  int _countdown = 30;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        t.cancel();
        setState(() => _countdown = 0);
      }
    });
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number with country code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).sendPhoneOTP(
        phoneNumber: phone,
        onCodeSent: (verId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verId;
            _isOtpSent = true;
            _isLoading = false;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to phone number! 📲')),
          );
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Phone Verification error: ${e.message}')),
          );
        },
        onVerificationCompleted: (cred) async {
          if (!mounted) return;
          final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
          if (userCred.user != null) {
            widget.onSuccess(userCred.user!);
          }
        },
        onCodeAutoRetrievalTimeout: (verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();
    if (code.length < 6 || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid 6-digit OTP code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCred = await ref.read(authServiceProvider).verifyPhoneOTP(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (!mounted) return;
      if (userCred.user != null) {
        widget.onSuccess(userCred.user!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isOtpSent ? 'Verify Phone OTP' : 'Phone Number Sign In',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_isOtpSent) ...[
            const Text('Enter country code & phone number to receive a 6-digit OTP.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 555-0199 or +91 9876543210',
                filled: true,
                fillColor: AppColors.surfaceLight,
                prefixIcon: Icon(Icons.phone_rounded, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 24),
            ShineButton(
              onTap: _isLoading ? null : _sendOTP,
              backgroundColor: AppColors.accent,
              glowColor: AppColors.accent,
              child: Center(
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send OTP Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            Text('Sent code to ${_phoneController.text.trim()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-Digit SMS Code',
                filled: true,
                fillColor: AppColors.surfaceLight,
                prefixIcon: Icon(Icons.lock_clock_outlined, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isOtpSent = false),
                  child: const Text('Change Number', style: TextStyle(color: AppColors.textMuted)),
                ),
                _countdown > 0
                    ? Text('Resend in ${_countdown}s', style: const TextStyle(color: AppColors.textMuted, fontSize: 13))
                    : TextButton(
                        onPressed: _sendOTP,
                        child: const Text('Resend OTP', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            ShineButton(
              onTap: _isLoading ? null : _verifyOTP,
              backgroundColor: AppColors.accent,
              glowColor: AppColors.accent,
              child: Center(
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify & Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _AuthMode { signIn, signUp, chooseUsername, forgotPassword }

class _SignUpDraft {
  final String name;
  final String phone;
  final String email;
  final String password;

  const _SignUpDraft({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });
}

/// Email Auth Card / Modal Widget matching the exact Welcome Card mockup layout
class _EmailAuthCard extends ConsumerStatefulWidget {
  final Function(User user) onSuccess;
  final VoidCallback? onPhoneSignIn;

  const _EmailAuthCard({
    required this.onSuccess,
    this.onPhoneSignIn,
  });

  @override
  ConsumerState<_EmailAuthCard> createState() => _EmailAuthCardState();
}

class _EmailAuthCardState extends ConsumerState<_EmailAuthCard> {
  _AuthMode _authMode = _AuthMode.signIn;
  bool _isPhoneMode = false;
  bool _isLoading = false;
  bool _rememberMe = true;

  _SignUpDraft? _signUpDraft;

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  final _nameShakeKey = GlobalKey<ShakeWidgetState>();
  final _emailShakeKey = GlobalKey<ShakeWidgetState>();
  final _phoneShakeKey = GlobalKey<ShakeWidgetState>();
  final _passwordShakeKey = GlobalKey<ShakeWidgetState>();
  final _confirmPasswordShakeKey = GlobalKey<ShakeWidgetState>();
  final _usernameShakeKey = GlobalKey<ShakeWidgetState>();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _usernameError;
  bool _isFormValid = false;
  String _selectedCountryCode = '+91';

  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  List<String> _usernameSuggestions = [];
  Timer? _usernameDebounce;

  bool get _isSignUp => _authMode == _AuthMode.signUp;
  bool get _isChooseUsername => _authMode == _AuthMode.chooseUsername;
  bool get _isForgotPassword => _authMode == _AuthMode.forgotPassword;
  bool get _isGoogleAuthFlow => _authMode == _AuthMode.chooseUsername && _signUpDraft == null;


  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
      _validateForm();
    });
    _emailController.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
      _validateForm();
    });
    _phoneController.addListener(() {
      if (_phoneError != null) setState(() => _phoneError = null);
      _validateForm();
    });
    _passwordController.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
      _validateForm();
    });
    _confirmPasswordController.addListener(_validateForm);
    _usernameController.addListener(_onUsernameChanged);

    _passwordFocusNode.addListener(_onFocusChange);
    _confirmPasswordFocusNode.addListener(_onFocusChange);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final profileService = ref.read(userProfileServiceProvider);
      profileService.fetchOrInitUserProfile(currentUser).then((res) {
        if (!mounted) return;
        if (res.profile.usernameDisplay == null || res.profile.usernameDisplay!.isEmpty) {
          ref.read(authServiceProvider).signOut();
          setState(() {
            _authMode = _AuthMode.signIn;
          });
        }
      });
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_onFocusChange);
    _confirmPasswordFocusNode.removeListener(_onFocusChange);
    _usernameDebounce?.cancel();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }


  void _clearFormControllers() {
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
    _usernameController.clear();
    _nameError = null;
    _emailError = null;
    _phoneError = null;
    _passwordError = null;
    _usernameError = null;
  }

  void _switchToSignUp() {
    setState(() {
      _authMode = _AuthMode.signUp;
      _isPhoneMode = false;
      _clearFormControllers();
      _validateForm();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  void _switchToSignIn() {
    setState(() {
      _authMode = _AuthMode.signIn;
      _isPhoneMode = false;
      _clearFormControllers();
      _validateForm();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emailFocusNode.requestFocus();
      }
    });
  }



  void _onUsernameChanged() {
    if (!_isChooseUsername) return;
    final text = _usernameController.text.trim();
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();

    if (text.isEmpty) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameSuggestions = generateUsernameSuggestions(_signUpDraft?.name ?? 'Athlete');
      });
      _validateForm();
      return;
    }

    // Live Tracking Suggestions: update username suggestions in real-time based on typing
    setState(() {
      _usernameSuggestions = generateUsernameSuggestions(text);
    });

    final syntaxError = validateUsernameSyntax(text);
    if (syntaxError != null) {
      setState(() {
        _usernameError = syntaxError;
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
      });
      _validateForm();
      return;
    }

    setState(() {
      _usernameError = null;
      _isCheckingUsername = true;
      _isUsernameAvailable = false;
    });
    _validateForm();

    _usernameDebounce = Timer(const Duration(milliseconds: 350), () async {
      final profileService = ref.read(userProfileServiceProvider);
      final isTaken = await profileService.isUsernameTaken(text);
      if (!mounted) return;
      if (text != _usernameController.text.trim()) return;

      setState(() {
        _isCheckingUsername = false;
        if (isTaken) {
          _isUsernameAvailable = false;
          _usernameError = 'Username "@$text" is already taken';
          _regenerateSuggestions(baseName: text);
        } else {
          _isUsernameAvailable = true;
          _usernameError = null;
        }
      });
      _validateForm();
    });
  }

  void _regenerateSuggestions({String? baseName}) {
    final nameToUse = (baseName != null && baseName.isNotEmpty)
        ? baseName
        : (_signUpDraft?.name ?? 'Athlete');
    final fresh = generateUsernameSuggestions(nameToUse);
    setState(() {
      _usernameSuggestions = fresh;
    });
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isEmailValid = email.contains('@') || email.length >= 3;
    final isPhoneValid = phone.isNotEmpty && phone.length >= 7;
    
    final hasMinLength = password.length >= 6;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final isPasswordValid = hasMinLength && hasLetter && hasDigit;

    setState(() {
      if (_isForgotPassword) {
        _isFormValid = isEmailValid;
      } else if (_isChooseUsername) {
        _isFormValid = _isUsernameAvailable && !_isCheckingUsername;
      } else if (_isSignUp) {
        final doPasswordsMatch = password.isNotEmpty && password == confirmPassword;
        _isFormValid = isEmailValid && isPhoneValid && isPasswordValid && doPasswordsMatch;
      } else {
        final identifierValid = _isPhoneMode ? isPhoneValid : isEmailValid;
        _isFormValid = identifierValid && password.isNotEmpty;
      }
    });
  }



  Future<void> _proceedToChooseUsernameDirectly() async {
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (name.isEmpty || RegExp(r'[^a-zA-Z\s]').hasMatch(name)) {
      setState(() => _nameError = "Name can only contain alphabets (A-Z, a-z)");
      _nameFocusNode.requestFocus();
      _nameShakeKey.currentState?.shake();
      return;
    }

    final phoneDigitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty || phoneDigitsOnly.length != 10) {
      setState(() => _phoneError = "Phone number must contain exactly 10 numeric digits (0-9)");
      _phoneFocusNode.requestFocus();
      _phoneShakeKey.currentState?.shake();
      return;
    }

    final fullPhoneInput = '$_selectedCountryCode$phoneDigitsOnly';

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegExp.hasMatch(email)) {
      setState(() => _emailError = "Email must be in a valid format (e.g. name@example.com)");
      _emailFocusNode.requestFocus();
      _emailShakeKey.currentState?.shake();
      return;
    }

    final hasMinLength = password.length >= 6;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);

    if (!hasMinLength || !hasLetter || !hasDigit) {
      setState(() {
        if (!hasMinLength) {
          _passwordError = "Password must be at least 6 characters long";
        } else if (!hasLetter) {
          _passwordError = "Password must contain letters (A-Z, a-z)";
        } else if (!hasDigit) {
          _passwordError = "Password must contain numbers (0-9)";
        }
      });
      _passwordFocusNode.requestFocus();
      _passwordShakeKey.currentState?.shake();
      return;
    }

    if (confirmPassword != password) {
      setState(() => _passwordError = "Passwords do not match");
      _confirmPasswordFocusNode.requestFocus();
      _confirmPasswordShakeKey.currentState?.shake();
      return;
    }

    final cleanPhone = normalizePhoneNumber(fullPhoneInput);

    final profileService = ref.read(userProfileServiceProvider);
    final isPhoneTaken = await profileService.isPhoneNumberTaken(cleanPhone);
    if (isPhoneTaken) {
      setState(() => _phoneError = "This phone number is already linked to another account. Please sign in.");
      _phoneFocusNode.requestFocus();
      _phoneShakeKey.currentState?.shake();
      return;
    }

    setState(() {
      _signUpDraft = _SignUpDraft(
        name: name,
        phone: cleanPhone,
        email: email,
        password: password,
      );
      _authMode = _AuthMode.chooseUsername;
      _usernameSuggestions = generateUsernameSuggestions(name);
      _usernameController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocusNode.requestFocus();
    });
    _onUsernameChanged();
  }



  Future<void> _completeRegistrationWithUsername() async {
    final chosenUsername = _usernameController.text.trim();
    final phoneInput = _phoneController.text.trim();

    if (_isGoogleAuthFlow && phoneInput.isNotEmpty) {
      final phoneDigitsOnly = phoneInput.replaceAll(RegExp(r'\D'), '');
      if (phoneDigitsOnly.length != 10) {
        setState(() => _phoneError = "Phone number must contain exactly 10 numeric digits");
        _phoneShakeKey.currentState?.shake();
        return;
      }
    }

    final rawPhone = phoneInput.isNotEmpty ? phoneInput : (_signUpDraft?.phone ?? '');
    final phoneToUse = rawPhone.isEmpty
        ? ''
        : (rawPhone.startsWith('+') ? rawPhone : '$_selectedCountryCode$rawPhone');

    final syntaxErr = validateUsernameSyntax(chosenUsername);
    if (syntaxErr != null) {
      setState(() => _usernameError = syntaxErr);
      _usernameShakeKey.currentState?.shake();
      return;
    }

    setState(() {
      _isLoading = true;
      _phoneError = null;
      _usernameError = null;
    });

    try {
      final profileService = ref.read(userProfileServiceProvider);
      final isTaken = await profileService.isUsernameTaken(chosenUsername);
      if (isTaken) {
        setState(() {
          _isLoading = false;
          _isUsernameAvailable = false;
          _usernameError = 'Username "@$chosenUsername" is already taken';
          _regenerateSuggestions(baseName: chosenUsername);
        });
        _usernameShakeKey.currentState?.shake();
        return;
      }

      final cleanPhone = normalizePhoneNumber(phoneToUse);
      final authService = ref.read(authServiceProvider);
      final currentUser = FirebaseAuth.instance.currentUser;
      User userToUse;

      if (_signUpDraft != null) {
        // Email & Password Registration flow:
        // If a Google user was signed in previously, sign out first to create a fresh Email account
        if (currentUser != null) {
          await authService.signOut();
        }
        final userCred = await authService.registerWithEmailPassword(
          email: _signUpDraft!.email,
          password: _signUpDraft!.password,
          displayName: _signUpDraft!.name,
        );
        if (userCred.user == null) throw Exception("User registration failed");
        userToUse = userCred.user!;
      } else if (currentUser != null) {
        // Google Sign-In flow: completing username & phone for active Google user session
        userToUse = currentUser;
      } else {
        throw Exception("No active registration session found.");
      }

      final existingResult = await profileService.fetchOrInitUserProfile(userToUse);
      final newProfile = existingResult.profile.copyWith(
        uid: userToUse.uid,
        email: userToUse.email ?? _signUpDraft?.email,
        phoneNumber: cleanPhone,
        name: (_signUpDraft?.name != null && _signUpDraft!.name.isNotEmpty)
            ? _signUpDraft!.name
            : (userToUse.displayName ?? existingResult.profile.name),
        usernameDisplay: chosenUsername,
        usernameLowercase: chosenUsername.toLowerCase(),
        isProfileComplete: false,
      );

      // Sync with Riverpod state immediately so onboarding step pages (Language, Unit, Profile Form) trigger
      ref.read(userProfileProvider.notifier).setProfile(newProfile);
      ref.read(isNewUserProvider.notifier).state = true;

      // Send Welcome Account Notification / Email
      final recipientEmail = userToUse.email ?? _signUpDraft?.email ?? newProfile.email ?? '';
      if (recipientEmail.isNotEmpty) {
        EmailOtpService.sendWelcomeNotification(
          email: recipientEmail,
          recipientName: newProfile.name,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Account created on Gymyzio! Welcome ${newProfile.name}!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );

      widget.onSuccess(userToUse);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'email-already-in-use') {
          _authMode = _AuthMode.signUp;
          _emailError = "An account already exists with this email. Please sign in.";
        } else {
          _usernameError = e.message ?? "Registration failed. Please try again.";
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_usernameError ?? 'Registration error'), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _handleKeyboardSubmit() {
    if (_isForgotPassword) {
      _forgotPassword();
    } else if (_isChooseUsername) {
      if (_isUsernameAvailable && !_isCheckingUsername && !_isLoading) {
        _completeRegistrationWithUsername();
      }
    } else if (_isSignUp) {
      _proceedToChooseUsernameDirectly();
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        if (identifier.isEmpty) {
          _emailError = "Please enter your email, phone number, or username";
          _emailShakeKey.currentState?.shake();
        }
        if (password.isEmpty) {
          _passwordError = "Please enter your password";
          _passwordShakeKey.currentState?.shake();
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profileService = ref.read(userProfileServiceProvider);
      String? targetEmail;

      if (identifier.contains('@') && identifier.contains('.')) {
        // 1. Email Address (e.g. user@gmail.com)
        targetEmail = identifier.toLowerCase();
      } else if (RegExp(r'^\+?\d[\d\s-]{6,}$').hasMatch(identifier)) {
        // 2. Phone Number (starts with + or contains digits) or numeric username
        targetEmail = await profileService.findEmailByPhoneNumber(identifier);
        if (targetEmail == null || targetEmail.isEmpty) {
          // Fallback to checking username in case identifier is a numeric username
          targetEmail = await profileService.findEmailByUsername(identifier);
        }
        if (targetEmail == null || targetEmail.isEmpty) {
          setState(() {
            _isLoading = false;
            _emailError = "No account found linked to this phone number or username. Please check or sign up.";
          });
          _emailShakeKey.currentState?.shake();
          return;
        }
      } else {
        // 3. Username (e.g. @john_doe or john_doe)
        targetEmail = await profileService.findEmailByUsername(identifier);
        if (targetEmail == null || targetEmail.isEmpty) {
          setState(() {
            _isLoading = false;
            _emailError = "No account found linked to username '$identifier'. Please check your credentials.";
          });
          _emailShakeKey.currentState?.shake();
          return;
        }
      }

      final userCred = await authService.signInWithEmailPassword(
        email: targetEmail.toLowerCase(),
        password: password,
      );

      if (!mounted) return;
      if (userCred.user != null) {
        final loggedUser = userCred.user!;
        final profileRes = await profileService.fetchOrInitUserProfile(loggedUser);
        ref.read(userProfileProvider.notifier).setProfile(profileRes.profile);
        ref.read(isNewUserProvider.notifier).state = profileRes.isNewUser;

        await ref.read(accountRegistryServiceProvider).saveOrUpdateAccount(
          SavedAccount(
            uid: loggedUser.uid,
            displayName: profileRes.profile.name,
            identifier: loggedUser.email ?? profileRes.profile.phoneNumber ?? identifier,
            photoUrl: loggedUser.photoURL,
            signInMethod: 'email',
            lastUsedAt: DateTime.now(),
          ),
        );

        widget.onSuccess(loggedUser);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'user-not-found') {
          _emailError = "No account found. Please check your credentials or register.";
          _emailShakeKey.currentState?.shake();
        } else if (e.code == 'wrong-password') {
          _passwordError = "Incorrect password. Please try again.";
          _passwordShakeKey.currentState?.shake();
        } else if (e.code == 'invalid-email') {
          _emailError = "Please enter a valid email, phone number, or username.";
          _emailShakeKey.currentState?.shake();
        } else if (e.code == 'invalid-credential') {
          _emailError = "Incorrect login credentials.";
          _passwordError = "Please check your password or register.";
          _emailShakeKey.currentState?.shake();
          _passwordShakeKey.currentState?.shake();
        } else {
          _emailError = e.message ?? "Sign in failed. Please try again.";
          _emailShakeKey.currentState?.shake();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailError = "Sign in error: ${e.toString()}";
        });
      }
    }
  }


  Future<void> _handleGoogleSignInModal() async {
    setState(() => _isLoading = true);
    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      if (credential != null && credential.user != null) {
        final user = credential.user!;
        final profileService = ref.read(userProfileServiceProvider);
        final result = await profileService.fetchOrInitUserProfile(user);

        if (result.profile.usernameDisplay == null || result.profile.usernameDisplay!.isEmpty) {
          setState(() {
            _signUpDraft = null;
            _authMode = _AuthMode.chooseUsername;
            _usernameSuggestions = generateUsernameSuggestions(user.displayName ?? 'Athlete');
            _usernameController.clear();
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _phoneFocusNode.requestFocus();
          });
        } else {
          widget.onSuccess(user);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In cancelled'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = "Please enter your email address first";
      });
      _emailFocusNode.requestFocus();
      _emailShakeKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your valid email address to receive reset link')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email 📧'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool passMismatch = _isSignUp &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text;

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context), width: 1),
        boxShadow: AppColors.softGlow(AppColors.primary, opacity: 0.15, blur: 24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Graphic Icon Area (Dumbbell Logo inside glowing dark circular container)
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80 * 0.22),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(80 * 0.12),
                child: Image.asset(
                  'assets/icon/app_icon_avatar.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Screen Title & Subtitle Line
          Text(
            _authMode == _AuthMode.signUp
                ? 'Sign Up'
                : (_authMode == _AuthMode.chooseUsername
                    ? 'Choose Username'
                    : (_authMode == _AuthMode.forgotPassword ? 'Forgot Password' : 'Sign In')),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _authMode == _AuthMode.signUp
                ? 'Create an account to start tracking your fitness'
                : (_authMode == _AuthMode.chooseUsername
                    ? 'Pick a unique username for your Gymyzio profile'
                    : (_authMode == _AuthMode.forgotPassword
                        ? 'Enter your registered email to receive a password reset link'
                        : 'Welcome back! Please enter your details')),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          // --- STEP 2: CHOOSE USERNAME SCREEN FORM ---
          if (_authMode == _AuthMode.chooseUsername) ...[
            if (_isGoogleAuthFlow) ...[
              ShakeWidget(
                key: _phoneShakeKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      onSubmitted: (_) => _usernameFocusNode.requestFocus(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Phone Number',
                        hintText: '9876543210',
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        prefixIcon: InkWell(
                          onTap: () => _openCountryPickerBottomSheet(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  kCountryCallingCodes.firstWhere((c) => c.code == _selectedCountryCode, orElse: () => kCountryCallingCodes.first).flag,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedCountryCode,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 22),
                                Container(
                                  height: 20,
                                  width: 1,
                                  margin: const EdgeInsets.only(left: 4, right: 8),
                                  color: AppColors.border,
                                ),
                              ],
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _phoneError != null ? Colors.redAccent : AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _phoneError != null ? Colors.redAccent : AppColors.primary, width: 1.8),
                        ),
                      ),
                    ),
                    if (_phoneError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(_phoneError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            ShakeWidget(
              key: _usernameShakeKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleKeyboardSubmit(),
                    style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                      hintText: 'enter username',
                      hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceLightOf(context),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 6),
                        child: Text(
                          '@',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _usernameError != null
                              ? Colors.redAccent
                              : (_isUsernameAvailable ? Colors.greenAccent : AppColors.borderOf(context)),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _usernameError != null
                              ? Colors.redAccent
                              : (_isUsernameAvailable ? Colors.greenAccent : AppColors.primary),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Real-time Status / Feedback message below field
                  if (_isCheckingUsername) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Text('Checking username availability...', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                        ],
                      ),
                    ),
                  ] else if (_usernameError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _usernameError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ] else if (_isUsernameAvailable) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                          SizedBox(width: 6),
                          Text('Username available ✨', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Username Suggestions Chips
            if (_usernameSuggestions.isNotEmpty) ...[
              Text(
                'Suggested Usernames:',
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _usernameSuggestions.map((suggestion) {
                  final isSelected = _usernameController.text.trim().toLowerCase() == suggestion.toLowerCase();
                  return InkWell(
                    onTap: () {
                      _usernameController.text = suggestion;
                      _usernameController.selection = TextSelection.fromPosition(TextPosition(offset: suggestion.length));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLightOf(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderOf(context),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        '@$suggestion',
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimaryOf(context),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Confirm Primary Action Button ("Create Account")
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isUsernameAvailable && !_isCheckingUsername && !_isLoading)
                    ? _completeRegistrationWithUsername
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text(
                        'Create Account',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 22),

            // Back to Step 1 link
            Center(
              child: GestureDetector(
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (mounted) {
                    setState(() {
                      _signUpDraft = null;
                      _authMode = _AuthMode.signIn;
                      _clearFormControllers();
                    });
                  }
                },
                child: const Text(
                  '← Edit account details',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ]

          // --- FORGOT PASSWORD SCREEN FORM ---
          else if (_authMode == _AuthMode.forgotPassword) ...[
            ShakeWidget(
              key: _emailShakeKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _forgotPassword(),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                      hintText: 'name@example.com',
                      hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceLightOf(context),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _emailError != null ? Colors.redAccent : AppColors.borderOf(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _emailError != null ? Colors.redAccent : AppColors.primary, width: 1.8),
                      ),
                    ),
                  ),
                  if (_emailError != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(_emailError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full-Width Solid Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _forgotPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // Secondary Link at Bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Remember your password? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                GestureDetector(
                  onTap: _switchToSignIn,
                  child: const Text(
                    'Sign in',
                    style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ]

          // --- SIGN IN & SIGN UP SCREENS FORMS ---
          else ...[
            // Combined Identifier Input (SIGN IN Mode Only)
            if (_authMode == _AuthMode.signIn) ...[
              ShakeWidget(
                key: _emailShakeKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Email, Phone, or Username',
                        labelStyle: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                        hintText: 'username, name@example.com, or +91 9876543210',
                        hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLightOf(context),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _emailError != null ? Colors.redAccent : AppColors.borderOf(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _emailError != null ? Colors.redAccent : AppColors.primary, width: 1.8),
                        ),
                      ),
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(_emailError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Full Name Input (SIGN UP Mode Only)
            if (_authMode == _AuthMode.signUp) ...[
              ShakeWidget(
                key: _nameShakeKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        TitleCaseTextInputFormatter(),
                      ],
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                        hintText: 'John Doe',
                        hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLightOf(context),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _nameError != null ? Colors.redAccent : AppColors.borderOf(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _nameError != null ? Colors.redAccent : AppColors.primary, width: 1.8),
                        ),
                      ),
                    ),
                    if (_nameError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(_nameError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Phone Number Input with Searchable Country Code Picker (SIGN UP Mode Only)
              ShakeWidget(
                key: _phoneShakeKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      onSubmitted: (_) => _emailFocusNode.requestFocus(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                        hintText: '9876543210',
                        hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLightOf(context),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        prefixIcon: InkWell(
                          onTap: () => _openCountryPickerBottomSheet(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  kCountryCallingCodes.firstWhere((c) => c.code == _selectedCountryCode, orElse: () => kCountryCallingCodes.first).flag,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedCountryCode,
                                  style: TextStyle(
                                    color: AppColors.textPrimaryOf(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 22),
                                Container(
                                  height: 20,
                                  width: 1,
                                  margin: const EdgeInsets.only(left: 4, right: 8),
                                  color: AppColors.borderOf(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _phoneError != null ? Colors.redAccent : AppColors.borderOf(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _phoneError != null ? Colors.redAccent : AppColors.primary, width: 1.8),
                        ),
                      ),
                    ),
                    if (_phoneError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(_phoneError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Email Address Input (SIGN UP Mode Only)
              ShakeWidget(
                key: _emailShakeKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        LowercaseTextInputFormatter(),
                      ],
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                        hintText: 'john@example.com',
                        hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLightOf(context),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _emailError != null ? Colors.redAccent : AppColors.borderOf(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _emailError != null ? Colors.redAccent : AppColors.primary, width: 1.8),
                        ),
                      ),
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(_emailError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Password Field Input
            ShakeWidget(
              key: _passwordShakeKey,
              child: PasswordField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                textInputAction: _authMode == _AuthMode.signUp ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_authMode == _AuthMode.signUp) {
                    _confirmPasswordFocusNode.requestFocus();
                  } else {
                    _handleKeyboardSubmit();
                  }
                },
                labelText: 'Password',
                errorText: _passwordError,
                hasError: passMismatch,
              ),
            ),

            // Confirm Password Input & Password Requirements Guide (SIGN UP Mode Only)
            if (_authMode == _AuthMode.signUp) ...[
              const SizedBox(height: 14),
              ShakeWidget(
                key: _confirmPasswordShakeKey,
                child: PasswordField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleKeyboardSubmit(),
                  labelText: 'Confirm Password',
                  hasError: passMismatch,
                  errorText: passMismatch ? 'Passwords do not match' : null,
                ),
              ),
              if (_passwordFocusNode.hasFocus || _confirmPasswordFocusNode.hasFocus) ...[
                _buildPasswordRequirementsGuide(_passwordController.text),
              ],
              const SizedBox(height: 12),
              // Terms & Privacy Policy Note (SIGN UP Mode Only)
              const Center(
                child: Text(
                  'By signing up, you agree to our Terms of Service & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
                ),
              ),
            ],

            // Remember Me & Forgot Password Row (SIGN IN Mode Only)
            if (_authMode == _AuthMode.signIn) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                if (val != null) setState(() => _rememberMe = val);
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _authMode = _AuthMode.forgotPassword;
                      _clearFormControllers();
                      _validateForm();
                    }),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forget password?',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Primary Full-Width Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isFormValid && !_isLoading)
                    ? (_authMode == _AuthMode.signUp ? _proceedToChooseUsernameDirectly : _submit)
                    : _handleKeyboardSubmit,

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _authMode == _AuthMode.signUp ? 'Continue' : 'Login',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // "Or continue with" Divider & Google Sign-In (SIGN IN Mode Only)
            if (_authMode == _AuthMode.signIn) ...[
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or continue with',
                      style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: InkWell(
                  onTap: _handleGoogleSignInModal,
                  borderRadius: BorderRadius.circular(12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                      SizedBox(width: 10),
                      Text(
                        'Google',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Bottom Secondary Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _authMode == _AuthMode.signUp ? 'Already have an account? ' : "Haven't any account? ",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {
                    if (_authMode == _AuthMode.signUp) {
                      _switchToSignIn();
                    } else {
                      _switchToSignUp();
                    }
                  },
                  child: Text(
                    _authMode == _AuthMode.signUp ? 'Sign in' : 'Sign up',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordRequirementsGuide(String password) {
    final hasMinLength = password.length >= 6;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final isStarted = password.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔑 Password Requirements:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _buildRequirementRow('At least 6 characters long', hasMinLength, isStarted),
          _buildRequirementRow('Contains letters (A-Z, a-z)', hasLetter, isStarted),
          _buildRequirementRow('Contains numbers (0-9)', hasDigit, isStarted),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String label, bool isMet, bool isStarted) {
    IconData icon;
    Color iconColor;

    if (isMet) {
      icon = Icons.check_circle_rounded;
      iconColor = Colors.green;
    } else if (isStarted) {
      icon = Icons.cancel_rounded; // Red cross icon when requirement is not satisfied!
      iconColor = Colors.redAccent;
    } else {
      icon = Icons.radio_button_unchecked_rounded;
      iconColor = AppColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isMet ? Colors.green : (isStarted ? Colors.redAccent : AppColors.textMuted),
                fontSize: 12,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCountryPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _CountryPickerBottomSheetContent(
          selectedCode: _selectedCountryCode,
          onSelect: (newCode) {
            setState(() {
              _selectedCountryCode = newCode;
            });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

class _CountryPickerBottomSheetContent extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onSelect;

  const _CountryPickerBottomSheetContent({
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  State<_CountryPickerBottomSheetContent> createState() => _CountryPickerBottomSheetContentState();
}

class _CountryPickerBottomSheetContentState extends State<_CountryPickerBottomSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = kCountryCallingCodes.where((item) {
      if (query.isEmpty) return true;
      return item.country.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query);
    }).toList();

    final currentSelected = kCountryCallingCodes.firstWhere(
      (item) => item.code == widget.selectedCode,
      orElse: () => kCountryCallingCodes.first,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderOf(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Select Country Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textMutedOf(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              autofocus: false,
              style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search country name or code (e.g. India, +91, A...)',
                hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.textMutedOf(context)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLightOf(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.borderOf(context)),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching countries found',
                      style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (query.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 20, top: 8, bottom: 4),
                          child: Text(
                            'CURRENTLY SELECTED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        _buildCountryTile(currentSelected, isSelected: true),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Divider(color: AppColors.borderOf(context), height: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
                          child: Text(
                            'ALL COUNTRIES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMutedOf(context),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                      ...filtered.map((item) {
                        final isSelected = item.code == widget.selectedCode;
                        return _buildCountryTile(item, isSelected: isSelected);
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryTile(CountryCallingCode item, {required bool isSelected}) {
    return InkWell(
      onTap: () => widget.onSelect(item.code),
      child: Container(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(item.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.country,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            Text(
              item.code,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class LowercaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

class CountryCallingCode {
  final String code;
  final String country;
  final String flag;

  const CountryCallingCode({
    required this.code,
    required this.country,
    required this.flag,
  });

  String get displayName => '$flag $code ($country)';
}

const List<CountryCallingCode> kCountryCallingCodes = [
  CountryCallingCode(code: '+91', country: 'India', flag: '🇮🇳'),
  CountryCallingCode(code: '+1', country: 'United States / Canada', flag: '🇺🇸'),
  CountryCallingCode(code: '+44', country: 'United Kingdom', flag: '🇬🇧'),
  CountryCallingCode(code: '+61', country: 'Australia', flag: '🇦🇺'),
  CountryCallingCode(code: '+971', country: 'United Arab Emirates', flag: '🇦🇪'),
  CountryCallingCode(code: '+966', country: 'Saudi Arabia', flag: '🇸🇦'),
  CountryCallingCode(code: '+65', country: 'Singapore', flag: '🇸🇬'),
  CountryCallingCode(code: '+49', country: 'Germany', flag: '🇩🇪'),
  CountryCallingCode(code: '+33', country: 'France', flag: '🇫🇷'),
  CountryCallingCode(code: '+81', country: 'Japan', flag: '🇯🇵'),
  CountryCallingCode(code: '+86', country: 'China', flag: '🇨🇳'),
  CountryCallingCode(code: '+92', country: 'Pakistan', flag: '🇵🇰'),
  CountryCallingCode(code: '+880', country: 'Bangladesh', flag: '🇧🇩'),
  CountryCallingCode(code: '+977', country: 'Nepal', flag: '🇳🇵'),
  CountryCallingCode(code: '+94', country: 'Sri Lanka', flag: '🇱🇰'),
  CountryCallingCode(code: '+60', country: 'Malaysia', flag: '🇲🇾'),
  CountryCallingCode(code: '+62', country: 'Indonesia', flag: '🇮🇩'),
  CountryCallingCode(code: '+66', country: 'Thailand', flag: '🇹🇭'),
  CountryCallingCode(code: '+84', country: 'Vietnam', flag: '🇻🇳'),
  CountryCallingCode(code: '+82', country: 'South Korea', flag: '🇰🇷'),
  CountryCallingCode(code: '+39', country: 'Italy', flag: '🇮🇹'),
  CountryCallingCode(code: '+34', country: 'Spain', flag: '🇪🇸'),
  CountryCallingCode(code: '+31', country: 'Netherlands', flag: '🇳🇱'),
  CountryCallingCode(code: '+41', country: 'Switzerland', flag: '🇨🇭'),
  CountryCallingCode(code: '+46', country: 'Sweden', flag: '🇸🇪'),
  CountryCallingCode(code: '+47', country: 'Norway', flag: '🇳🇴'),
  CountryCallingCode(code: '+353', country: 'Ireland', flag: '🇮🇪'),
  CountryCallingCode(code: '+55', country: 'Brazil', flag: '🇧🇷'),
  CountryCallingCode(code: '+52', country: 'Mexico', flag: '🇲🇽'),
  CountryCallingCode(code: '+54', country: 'Argentina', flag: '🇦🇷'),
  CountryCallingCode(code: '+27', country: 'South Africa', flag: '🇿🇦'),
  CountryCallingCode(code: '+20', country: 'Egypt', flag: '🇪🇬'),
  CountryCallingCode(code: '+234', country: 'Nigeria', flag: '🇳🇬'),
  CountryCallingCode(code: '+254', country: 'Kenya', flag: '🇰🇪'),
  CountryCallingCode(code: '+64', country: 'New Zealand', flag: '🇳🇿'),
  CountryCallingCode(code: '+7', country: 'Russia', flag: '🇷🇺'),
  CountryCallingCode(code: '+90', country: 'Turkey', flag: '🇹🇷'),
];

String toTitleCase(String text) {
  if (text.trim().isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}

class TitleCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final String text = newValue.text;
    final StringBuffer buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ') {
        capitalizeNext = true;
        buffer.write(char);
      } else if (capitalizeNext && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (RegExp(r'[a-zA-Z0-9]').hasMatch(char)) {
          capitalizeNext = false;
        }
      }
    }

    final String formatted = buffer.toString();
    int selectionIndex = newValue.selection.end;
    if (selectionIndex > formatted.length) {
      selectionIndex = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
