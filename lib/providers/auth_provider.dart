import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../providers/app_state_providers.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for UserProfileService singleton
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

/// StreamProvider watching Firebase authStateChanges()
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Flag indicating if active user is a new user (needs onboarding)
final isNewUserProvider = StateProvider<bool>((ref) => false);

/// Provider for the active Firebase User
final currentUserProvider = Provider<User?>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value ?? ref.watch(authServiceProvider).getCurrentUser();
});

/// Provider for User Display Name with fallback to profile name
final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  final profileName = ref.watch(userProfileProvider).name;
  if (user?.displayName != null && user!.displayName!.isNotEmpty) {
    return user.displayName!;
  }
  if (profileName.isNotEmpty && profileName != 'Athlete') {
    return profileName;
  }
  return 'Athlete';
});

/// Provider for User Email with fallback
final userEmailProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  final profileEmail = ref.watch(userProfileProvider).email;
  if (user?.email != null && user!.email!.isNotEmpty) {
    return user.email!;
  }
  if (profileEmail != null && profileEmail.isNotEmpty) {
    return profileEmail;
  }
  return 'No email registered';
});

/// Provider for User Photo URL
final userPhotoUrlProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.photoURL;
});
