import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/auth_provider.dart';
import '../services/account_registry_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientScale;
  late Animation<double> _logoScale;
  late Animation<double> _logoTranslate;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _gradientScale = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _logoTranslate = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeIn)),
    );

    _controller.forward();

    // Auto-navigate after 2.2 seconds based on Auth & Firestore profile state
    _navigationTimer = Timer(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Fetch or init user profile from Firestore
        final profileService = ref.read(userProfileServiceProvider);
        final result = await profileService.fetchOrInitUserProfile(currentUser);

        // Update Riverpod user profile state
        ref.read(userProfileProvider.notifier).setProfile(result.profile);
        ref.read(isNewUserProvider.notifier).state = result.isNewUser;

        if (!mounted) return;

        // Check if user has strictly completed full profile setup
        if (result.profile.isFullyCompleted) {
          // Keep local device account registry up to date for completed accounts
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
              displayName: currentUser.displayName ?? result.profile.name,
              identifier: currentUser.email ?? currentUser.phoneNumber ?? result.profile.email ?? 'Athlete',
              photoUrl: currentUser.photoURL,
              signInMethod: method,
              lastUsedAt: DateTime.now(),
            ),
          );

          if (!mounted) return;
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Parallax Layer (Clean White / Off-White Radial Gradient)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _gradientScale.value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 1.2,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFF8FAFC),
                        Color(0xFFF1F5F9),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Foreground Content (Logo & Tagline)
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _logoTranslate.value),
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon Badge
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
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
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/icon/app_icon_avatar.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // App Title
                          ShaderMask(
                            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                            child: const Text(
                              'Gymyzio',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'Fitness, Health & Guide',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
