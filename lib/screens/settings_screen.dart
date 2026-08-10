import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../services/account_registry_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../utils/phone_utils.dart';
import '../utils/username_utils.dart';
import '../utils/unit_converter.dart';
import '../utils/body_metrics_calculator.dart';
import '../widgets/responsive_web_wrapper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditProfileModal(profile: profile),
    );
  }

  void _showPhotoPickerOptions(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(ctx),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you\'d like to update your photo',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(ctx)),
                ),
                const SizedBox(height: 20),
                _buildPhotoOption(
                  ctx,
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  sublabel: 'Use your camera',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSavePhoto(context, ref, ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                _buildPhotoOption(
                  ctx,
                  icon: Icons.photo_library_rounded,
                  label: 'Upload from Gallery',
                  sublabel: 'Choose from camera roll',
                  color: const Color(0xFF0D9488),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSavePhoto(context, ref, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _buildPhotoOption(
                  ctx,
                  icon: Icons.folder_open_rounded,
                  label: 'Browse Files',
                  sublabel: 'Pick from your device storage',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSavePhoto(context, ref, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                // Remove photo option (if photo exists)
                Consumer(
                  builder: (c, r, _) {
                    final hasCustom = r.watch(customPhotoUrlProvider) != null;
                    if (!hasCustom) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const Divider(height: 20),
                        _buildPhotoOption(
                          ctx,
                          icon: Icons.delete_outline_rounded,
                          label: 'Remove Photo',
                          sublabel: 'Reset to default avatar',
                          color: Colors.redAccent,
                          onTap: () {
                            Navigator.pop(ctx);
                            r.read(customPhotoUrlProvider.notifier).clearPhoto();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context), fontSize: 15)),
                  Text(sublabel, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMutedOf(context)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSavePhoto(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      final mimeType = file.mimeType ?? 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64Str';

      await ref.read(customPhotoUrlProvider.notifier).setPhoto(dataUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Profile photo updated!', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.settingsAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<bool> _showInPlaceReauthDialog(BuildContext context, User currentUser) async {
    final isGoogleUser = currentUser.providerData.any((p) => p.providerId == 'google.com');

    if (isGoogleUser) {
      try {
        if (kIsWeb) {
          final GoogleAuthProvider googleProvider = GoogleAuthProvider();
          await currentUser.reauthenticateWithPopup(googleProvider);
          return true;
        } else {
          final GoogleSignInAccount? googleUser = await GoogleSignIn(
            clientId: kIsWeb ? '991712237098-r8goommung4n32qbvqai5lv16g3cmkk9.apps.googleusercontent.com' : null,
            serverClientId: kIsWeb ? null : '991712237098-r8goommung4n32qbvqai5lv16g3cmkk9.apps.googleusercontent.com',
          ).signIn();
          if (googleUser == null) return false;
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await currentUser.reauthenticateWithCredential(credential);
          return true;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google re-authentication failed: ${e.toString()}')),
          );
        }
        return false;
      }
    }

    final passwordController = TextEditingController();
    String? errorMessage;
    bool isLoading = false;
    bool obscurePassword = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Re-Authenticate',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For security reasons, please enter your password to confirm account deletion.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            setState(() => errorMessage = 'Please enter your password');
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final email = currentUser.email ?? '';
                            if (email.isEmpty) {
                              throw Exception('No email associated with this account');
                            }
                            final credential = EmailAuthProvider.credential(
                              email: email,
                              password: password,
                            );
                            await currentUser.reauthenticateWithCredential(credential);
                            if (ctx.mounted) {
                              Navigator.pop(ctx, true);
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              isLoading = false;
                              if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                                errorMessage = 'Incorrect password. Please try again.';
                              } else {
                                errorMessage = e.message ?? 'Authentication failed';
                              }
                            });
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = e.toString();
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirm & Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all your workout data. This cannot be undone. Are you sure?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Forever', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final profile = ref.read(userProfileProvider);
    final String uid = (currentUser?.uid != null && currentUser!.uid.isNotEmpty)
        ? currentUser.uid
        : (profile.uid ?? '');

    if (uid.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active account session found.')),
        );
      }
      return;
    }

    final bool isGoogleUser = currentUser != null &&
        currentUser.providerData.any((p) => p.providerId == 'google.com');

    if (currentUser != null) {
      if (!context.mounted) return;
      if (isGoogleUser) {
        // For Google Auth users: prompt direct verification dialog
        final bool confirmGoogleDel = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 32),
                SizedBox(width: 8),
                Text('Confirm Google Deletion', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              ],
            ),
            content: const Text(
              'Are you sure you want to permanently delete your Google-linked Gymyzio account and all database records?',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm & Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;
        if (!confirmGoogleDel) return;
      } else {
        // For Email/Password users: require password verification
        final bool reauthenticated = await _showInPlaceReauthDialog(context, currentUser);
        if (!reauthenticated) return;
      }
    }

    void showLoadingOverlay() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [
              CircularProgressIndicator(color: Colors.redAccent),
              SizedBox(width: 20),
              Expanded(
                child: Text('Deleting account & database records...', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    showLoadingOverlay();

    try {
      // 1. Delete Firestore user document & subcollections (workouts, weight logs, history)
      await ref.read(userProfileServiceProvider).deleteUserProfile(uid);

      // 2. Remove account from device AccountRegistryService so it won't appear in Switch Account
      await ref.read(accountRegistryServiceProvider).removeAccount(uid);

      // 3. Delete Firebase Auth User account
      if (currentUser != null) {
        try {
          await currentUser.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            if (isGoogleUser) {
              await ref.read(authServiceProvider).signInWithGoogle();
              final freshUser = FirebaseAuth.instance.currentUser;
              if (freshUser != null) await freshUser.delete();
            } else {
              throw Exception("Please sign out and sign in again to verify account deletion.");
            }
          } else {
            rethrow;
          }
        }
      }

      // 4. Reset Riverpod local state and sign out
      ref.read(userProfileProvider.notifier).reset();
      ref.read(userActivityProvider.notifier).reset();
      await ref.read(authServiceProvider).signOut();

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account permanently deleted'),
            backgroundColor: Colors.redAccent,
          ),
        );
        context.go('/onboarding');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deletion note: ${e.toString()}')),
        );
        // Force redirect to sign in window even if auth session was invalidated
        context.go('/onboarding');
      }
    }
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final tr = ref.watch(trProvider);
    final formatWeight = ref.watch(weightFormatterProvider);
    final formatHeight = ref.watch(heightFormatterProvider);
    final displayName = ref.watch(userDisplayNameProvider);
    final email = ref.watch(userEmailProvider);
    final photoUrl = ref.watch(userPhotoUrlProvider);

    final customBmi = ref.watch(customBmiOverrideProvider);
    final customBodyFat = ref.watch(customBodyFatOverrideProvider);

    final calculatedBmi = customBmi ??
        (profile.height > 0 && profile.weight > 0
            ? BodyMetricsCalculator.calculateBMI(
                height: profile.height,
                weight: profile.weight,
                unitSystem: profile.unitSystem,
              )
            : 22.8);

    final calculatedBodyFat = customBodyFat ??
        (calculatedBmi > 0
            ? BodyMetricsCalculator.calculateBodyFat(
                bmi: calculatedBmi,
                age: profile.age > 0 ? profile.age : 24,
                isMale: true,
              )
            : 15.4);

    const accentColor = AppColors.settingsAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradientOf(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr('settings_title'), style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        ),
        body: ResponsiveWebWrapper(
          maxWidth: 900,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card Header with Real Firebase Auth Data & Purple Glow Accent
              _buildUserHeaderCard(
                profile: profile,
                displayName: displayName,
                email: email,
                photoUrl: photoUrl,
                calculatedBmi: calculatedBmi,
                calculatedBodyFat: calculatedBodyFat,
                formatWeight: formatWeight,
                formatHeight: formatHeight,
                accentColor: accentColor,
                onEditTap: () => _showEditProfileModal(context, ref, profile),
                onPhotoTap: () => _showPhotoPickerOptions(context, ref),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),

              // Live State Preview Verification Box
              Text(
                'Live State Preview (Riverpod Wired)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  boxShadow: AppColors.softGlow(accentColor, opacity: 0.1, blur: 10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Language: ${profile.language}  |  Unit System: ${profile.unitSystem}\nAccount: $displayName ($email) ${profile.phoneNumber != null ? "| Phone: ${profile.phoneNumber}" : ""}\nBody Fat: $calculatedBodyFat%  |  BMI Score: $calculatedBmi',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 28),

              // General Settings Group
              Text(
                tr('app_preferences'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),

              // Appearance (Light / Dark Mode Toggle Selector)
              Consumer(
                builder: (context, ref, child) {
                  final themeMode = ref.watch(themeModeProvider);
                  final bool isDark = themeMode == ThemeMode.dark;
                  final String subtitleText = isDark ? 'Dark Mode Active' : 'Light Mode Active';
                  final IconData leadingIcon = isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded;

                  Widget buildPill(ThemeMode mode, String label, IconData icon) {
                    final bool isSelected = themeMode == mode;
                    return GestureDetector(
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isSelected ? Colors.white : AppColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return _buildSettingTile(
                    icon: leadingIcon,
                    title: 'Appearance',
                    subtitle: subtitleText,
                    accentColor: accentColor,
                    trailing: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLightOf(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildPill(ThemeMode.light, 'Light', Icons.light_mode_rounded),
                          const SizedBox(width: 4),
                          buildPill(ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
                        ],
                      ),
                    ),
                  );
                },
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              // Language Switcher Tile
              _buildSettingTile(
                icon: Icons.language_rounded,
                title: tr('app_language'),
                subtitle: profile.language,
                accentColor: accentColor,
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: profile.language,
                    dropdownColor: AppColors.surfaceLight,
                    items: ['English', 'हिंदी'].map((lang) {
                      return DropdownMenuItem(value: lang, child: Text(lang));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(userProfileProvider.notifier).setLanguage(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Language updated to $val')),
                        );
                      }
                    },
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              // Unit System Switcher Tile
              _buildSettingTile(
                icon: Icons.straighten_rounded,
                title: tr('unit_system'),
                subtitle: profile.unitSystem == 'Metric' ? 'Metric (kg, cm)' : 'Imperial (lbs, in)',
                accentColor: accentColor,
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: profile.unitSystem,
                    dropdownColor: AppColors.surfaceLight,
                    items: ['Metric', 'Imperial'].map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(userProfileProvider.notifier).setUnitSystem(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unit system updated to $val')),
                        );
                      }
                    },
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 28),

              // Data & Account Actions Group
              Text(
                tr('account_data'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),

              // Export Data Button Tile
              AppBouncyTap(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export coming soon in v1.1! 📦'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                child: _buildSettingTile(
                  icon: Icons.file_download_outlined,
                  title: tr('export_data'),
                  subtitle: 'Download CSV or JSON history log',
                  accentColor: accentColor,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 250.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              // Switch Account Button Tile
              AppBouncyTap(
                onTap: () => context.push('/switch-account'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    boxShadow: AppColors.softGlow(AppColors.secondary, opacity: 0.1, blur: 10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.switch_account_rounded, color: AppColors.secondary),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Switch Account', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            SizedBox(height: 2),
                            Text('Log into a different Google, Phone, or Email account', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.secondary),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 280.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              // Real Firebase Auth Sign Out Button Tile
              AppBouncyTap(
                onTap: () async {
                  ref.read(userProfileProvider.notifier).reset();
                  ref.read(userActivityProvider.notifier).reset();
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Signed out successfully!'),
                      ),
                    );
                    context.go('/onboarding');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('sign_out'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            const SizedBox(height: 2),
                            const Text('Sign out of active session', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.redAccent),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),

              // Destructive Delete Account Button Tile
              AppBouncyTap(
                onTap: () => _handleDeleteAccount(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                    boxShadow: AppColors.softGlow(Colors.redAccent, opacity: 0.2, blur: 12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Permanently erase account profile & all workout data',
                              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 320.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 40),

              // App Version Footer
              const Center(
                child: Text(
                  'Gymyzio Prototype v1.0.0 • Firebase Auth Enabled',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildUserHeaderCard({
    required UserProfile profile,
    required String displayName,
    required String email,
    required String? photoUrl,
    required double calculatedBmi,
    required double calculatedBodyFat,
    required String Function(double, {int decimals, bool includeUnit}) formatWeight,
    required String Function(double, {bool includeUnit}) formatHeight,
    required Color accentColor,
    required VoidCallback onEditTap,
    required VoidCallback onPhotoTap,
  }) {
    final phoneStr = profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty
        ? profile.phoneNumber!
        : 'No phone number added';

    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(AppRadius.container),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            boxShadow: AppColors.softGlow(accentColor, opacity: 0.15, blur: 14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Avatar with pencil edit overlay
              GestureDetector(
                onTap: onPhotoTap,
                child: Stack(
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: photoUrl.startsWith('data:')
                            ? MemoryImage(base64Decode(photoUrl.split(',').last)) as ImageProvider
                            : NetworkImage(photoUrl),
                        backgroundColor: accentColor,
                      )
                    else
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: accentColor,
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.usernameDisplay != null && profile.usernameDisplay!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${profile.usernameDisplay}',
                        style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_iphone_rounded, size: 13, color: AppColors.textMutedOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          phoneStr,
                          style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.ageFormatted} • ${profile.weightFormatted} • ${profile.heightFormatted}',
                      style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Body Fat: $calculatedBodyFat%',
                            style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'BMI Score: $calculatedBmi',
                            style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditTap,
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.settingsAccent),
                tooltip: 'Edit Profile',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.settingsAccent.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget trailing,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        );
      },
    );
  }
}

class _EditProfileModal extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _EditProfileModal({required this.profile});

  @override
  ConsumerState<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<_EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;

  late String _selectedGoal;
  late String _selectedExperience;

  bool _isLoading = false;
  String? _phoneError;
  String? _nameError;
  String? _usernameError;
  String? _ageError;
  String? _weightError;
  String? _heightError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _usernameController = TextEditingController(text: widget.profile.usernameDisplay ?? '');
    _phoneController = TextEditingController(text: widget.profile.phoneNumber ?? '');
    _ageController = TextEditingController(text: widget.profile.age > 0 ? widget.profile.age.toString() : '');

    final displayWeight = widget.profile.weight > 0 ? UnitConverter.convertWeight(widget.profile.weight, widget.profile.unitSystem) : 75.0;
    _weightController = TextEditingController(
      text: displayWeight % 1 == 0 ? displayWeight.toInt().toString() : displayWeight.toStringAsFixed(1),
    );

    final displayHeightCm = widget.profile.height > 0 ? widget.profile.height : 178.0;
    _heightController = TextEditingController(
      text: displayHeightCm % 1 == 0 ? displayHeightCm.toInt().toString() : displayHeightCm.toStringAsFixed(1),
    );

    final ftIn = UnitConverter.cmToFeetInches(displayHeightCm);
    _heightFeetController = TextEditingController(text: ftIn.feet > 0 ? ftIn.feet.toString() : '5');
    _heightInchesController = TextEditingController(
      text: ftIn.inches % 1 == 0 ? ftIn.inches.toInt().toString() : ftIn.inches.toStringAsFixed(1),
    );

    const goalOptions = ['Strength', 'Cardio', 'Both', 'Muscle Gain', 'Weight Loss', 'Maintenance', 'Endurance', 'General Fitness'];
    const expOptions = ['Beginner', 'Intermediate', 'Advanced'];

    _selectedGoal = goalOptions.contains(widget.profile.goal) ? widget.profile.goal : 'Strength';
    _selectedExperience = expOptions.contains(widget.profile.experienceLevel) ? widget.profile.experienceLevel : 'Intermediate';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? widget.profile.age;

    final rawWeightInput = double.tryParse(_weightController.text.trim()) ?? 0.0;
    double weightKg = 0.0;
    if (widget.profile.unitSystem == 'Imperial') {
      weightKg = UnitConverter.lbsToKg(rawWeightInput);
    } else {
      weightKg = rawWeightInput;
    }
    if (weightKg <= 0) weightKg = widget.profile.weight;

    double heightCm = 0.0;
    if (widget.profile.unitSystem == 'Imperial') {
      final ft = int.tryParse(_heightFeetController.text.trim()) ?? 0;
      final inch = double.tryParse(_heightInchesController.text.trim()) ?? 0.0;
      heightCm = UnitConverter.feetInchesToCm(ft, inch);
    } else {
      heightCm = double.tryParse(_heightController.text.trim()) ?? 0.0;
    }
    if (heightCm <= 0) heightCm = widget.profile.height;

    String? uError;
    if (username.isNotEmpty) {
      uError = validateUsernameSyntax(username);
    }

    setState(() {
      _nameError = name.isEmpty ? 'Name cannot be empty' : null;
      _phoneError = phone.isEmpty
          ? 'Phone number is required'
          : (phone.length < 7 ? 'Enter a valid phone number' : null);
      _usernameError = uError;
      _ageError = age <= 0 ? 'Enter a valid age' : null;
      _weightError = weightKg <= 0 ? 'Enter a valid weight' : null;
      _heightError = heightCm <= 0 ? 'Enter a valid height' : null;
    });

    if (_nameError != null || _phoneError != null || _usernameError != null || _ageError != null || _weightError != null || _heightError != null) return;

    setState(() => _isLoading = true);

    try {
      final profileService = ref.read(userProfileServiceProvider);

      if (username.isNotEmpty && username.toLowerCase() != (widget.profile.usernameLowercase ?? '')) {
        final isTaken = await profileService.isUsernameTaken(username, excludeUid: widget.profile.uid);
        if (isTaken) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _usernameError = 'Username "@$username" is already taken';
          });
          return;
        }
      }

      final cleanPhone = normalizePhoneNumber(phone);
      final updatedProfile = widget.profile.copyWith(
        name: name,
        usernameDisplay: username.isNotEmpty ? username : widget.profile.usernameDisplay,
        usernameLowercase: username.isNotEmpty ? username.toLowerCase() : widget.profile.usernameLowercase,
        phoneNumber: cleanPhone,
        age: age,
        weight: weightKg,
        height: heightCm,
        goal: _selectedGoal,
        experienceLevel: _selectedExperience,
      );

      // Save to Firestore
      await profileService.saveUserProfile(updatedProfile);

      // Update Riverpod state
      ref.read(userProfileProvider.notifier).setProfile(updatedProfile);

      // Update Firebase Auth user display name if currentUser exists
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && name != currentUser.displayName) {
        await currentUser.updateDisplayName(name);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! ✨'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentUnit = widget.profile.unitSystem;
    final weightUnitLabel = currentUnit == 'Imperial' ? 'lbs' : 'kg';

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_rounded, color: AppColors.settingsAccent),
                    SizedBox(width: 8),
                    Text(
                      'Edit Profile Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name Field
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                TitleCaseTextInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.settingsAccent),
                errorText: _nameError,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Username Field
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 6),
                  child: Text('@', style: TextStyle(color: AppColors.settingsAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                errorText: _usernameError,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Phone Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Required)',
                hintText: '+91 9876543210',
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.settingsAccent),
                errorText: _phoneError,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Age Stepper Field
            _buildModalStepperField(
              controller: _ageController,
              label: 'Age',
              hintText: 'Enter your age (e.g. 24)',
              suffix: 'years',
              icon: Icons.cake_outlined,
              errorText: _ageError,
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
            ),
            const SizedBox(height: 14),

            // Weight Stepper Field
            _buildModalStepperField(
              controller: _weightController,
              label: 'Weight ($weightUnitLabel)',
              hintText: 'Enter your weight (e.g. 75 $weightUnitLabel)',
              suffix: weightUnitLabel,
              isDecimal: true,
              icon: Icons.fitness_center_rounded,
              errorText: _weightError,
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
            ),
            const SizedBox(height: 14),

            // Height Stepper Field (Imperial Dual ft/in vs Metric CM)
            if (currentUnit == 'Imperial') ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildModalStepperField(
                      controller: _heightFeetController,
                      label: 'Height (ft)',
                      hintText: 'e.g. 5',
                      suffix: 'ft',
                      icon: Icons.height_rounded,
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModalStepperField(
                      controller: _heightInchesController,
                      label: 'Inches (in)',
                      hintText: 'e.g. 8',
                      suffix: 'in',
                      isDecimal: true,
                      icon: Icons.height_rounded,
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
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildModalStepperField(
                controller: _heightController,
                label: 'Height (cm)',
                hintText: 'Enter your height (e.g. 178 cm)',
                suffix: 'cm',
                isDecimal: true,
                icon: Icons.height_rounded,
                errorText: _heightError,
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
              ),
            ],
            const SizedBox(height: 14),

            // Goal Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedGoal,
              dropdownColor: AppColors.surfaceLight,
              decoration: InputDecoration(
                labelText: 'Fitness Goal',
                prefixIcon: const Icon(Icons.fitness_center_rounded, color: AppColors.settingsAccent),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Strength', 'Cardio', 'Both', 'Muscle Gain', 'Weight Loss', 'Maintenance', 'Endurance', 'General Fitness'].map((g) {
                return DropdownMenuItem(value: g, child: Text(g));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGoal = val);
              },
            ),
            const SizedBox(height: 14),

            // Experience Level Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedExperience,
              dropdownColor: AppColors.surfaceLight,
              decoration: InputDecoration(
                labelText: 'Experience Level',
                prefixIcon: const Icon(Icons.star_outline_rounded, color: AppColors.settingsAccent),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Beginner', 'Intermediate', 'Advanced'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedExperience = val);
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.settingsAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalStepperField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    String? suffix,
    String? errorText,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? Colors.redAccent : AppColors.border,
              width: errorText != null ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDecrement,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppColors.settingsAccent,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: AppColors.settingsAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: isDecimal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    suffixText: suffix != null ? ' $suffix' : null,
                    suffixStyle: const TextStyle(
                      color: AppColors.settingsAccent,
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onIncrement,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.settingsAccent,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
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
