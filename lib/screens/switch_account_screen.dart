import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../providers/auth_provider.dart';
import '../services/account_registry_service.dart';
import '../widgets/shine_button.dart';
import '../widgets/password_field.dart';
import '../widgets/shake_widget.dart';
import '../widgets/responsive_web_wrapper.dart';

class SwitchAccountScreen extends ConsumerStatefulWidget {
  const SwitchAccountScreen({super.key});

  @override
  ConsumerState<SwitchAccountScreen> createState() => _SwitchAccountScreenState();
}

class _SwitchAccountScreenState extends ConsumerState<SwitchAccountScreen> {
  List<SavedAccount> _savedAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await ref.read(accountRegistryServiceProvider).getSavedAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmRemoveAccount(SavedAccount account) async {
    final accountName = account.displayName ?? account.identifier;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Account', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Remove $accountName from this device\'s account list? This won\'t delete their account.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
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
            child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(accountRegistryServiceProvider).removeAccount(account.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $accountName from account list')),
      );
      _loadAccounts();
    }
  }

  /// Critical Post-Switch State Refresh: refetches profile & clears stale data for new account
  Future<void> _performPostSwitchStateRefresh(User newUser) async {
    final profileService = ref.read(userProfileServiceProvider);
    final result = await profileService.fetchOrInitUserProfile(newUser);

    // Update user profile state in Riverpod
    ref.read(userProfileProvider.notifier).setProfile(result.profile);
    ref.read(isNewUserProvider.notifier).state = result.isNewUser;

    // Reset active workout, rest timer, and user activity so zero stale data remains from previous session
    ref.read(activeWorkoutProvider.notifier).clearWorkout();
    ref.read(restTimerProvider.notifier).reset();
    ref.read(userActivityProvider.notifier).reset();

    // Determine sign-in method
    String method = 'email';
    if (newUser.providerData.isNotEmpty) {
      final p = newUser.providerData.first.providerId;
      if (p.contains('google')) {
        method = 'google';
      } else if (p.contains('phone')) {
        method = 'phone';
      }
    } else if (newUser.phoneNumber != null && newUser.phoneNumber!.isNotEmpty) {
      method = 'phone';
    }

    final identifier = newUser.email ?? newUser.phoneNumber ?? result.profile.email ?? 'Athlete';

    // Update device account registry's lastUsedAt for the newly active account
    await ref.read(accountRegistryServiceProvider).saveOrUpdateAccount(
      SavedAccount(
        uid: newUser.uid,
        displayName: newUser.displayName ?? result.profile.name,
        identifier: identifier,
        photoUrl: newUser.photoURL,
        signInMethod: method,
        lastUsedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;

    final displayName = newUser.displayName ?? result.profile.name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to $displayName ($identifier) 🎉'),
        backgroundColor: AppColors.primary,
      ),
    );

    // Navigate to Home Dashboard showing newly active account's own data
    context.go('/home');
  }

  void _handleAuthError(FirebaseAuthException e) {
    if (!mounted) return;
    if (e.code == 'network-request-failed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your connection and try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth error: ${e.message ?? e.code}')),
      );
    }
  }

  /// Switch to selected saved account based on its signInMethod
  void _onSelectAccountToSwitch(SavedAccount account) async {
    if (account.signInMethod == 'google') {
      await _handleSwitchGoogleAccount(account);
    } else if (account.signInMethod == 'phone') {
      _showPhoneReAuthBottomSheet(context, account);
    } else {
      _showEmailReAuthBottomSheet(context, account);
    }
  }

  /// Switch Google Account
  Future<void> _handleSwitchGoogleAccount(SavedAccount account) async {
    try {
      await ref.read(authServiceProvider).signOut();

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final userCred = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        if (userCred.user != null) {
          await _performPostSwitchStateRefresh(userCred.user!);
        }
        return;
      }

      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '991712237098-r8goommung4n32qbvqai5lv16g3cmkk9.apps.googleusercontent.com' : null,
        serverClientId: kIsWeb ? null : '991712237098-r8goommung4n32qbvqai5lv16g3cmkk9.apps.googleusercontent.com',
      );
      GoogleSignInAccount? googleUser;

      try {
        // Attempt silent sign-in first
        googleUser = await googleSignIn.signInSilently();
      } catch (_) {
        googleUser = null;
      }

      // If silent sign-in failed or returned wrong user, open picker
      if (googleUser == null || (googleUser.email != account.identifier)) {
        googleUser = await googleSignIn.signIn();
      }

      if (googleUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not switch automatically. Please sign in again.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCred.user != null) {
        await _performPostSwitchStateRefresh(userCred.user!);
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to switch Google account: ${e.toString()}')),
      );
    }
  }

  /// Email Re-Auth Bottom Sheet Modal
  void _showEmailReAuthBottomSheet(BuildContext context, SavedAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EmailReAuthModal(
        account: account,
        onSuccess: (newUser) async {
          Navigator.pop(ctx);
          await _performPostSwitchStateRefresh(newUser);
        },
      ),
    );
  }

  /// Phone Re-Auth Bottom Sheet Modal
  void _showPhoneReAuthBottomSheet(BuildContext context, SavedAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PhoneReAuthModal(
        account: account,
        onSuccess: (newUser) async {
          Navigator.pop(ctx);
          await _performPostSwitchStateRefresh(newUser);
        },
      ),
    );
  }

  Widget _buildMethodIcon(String method) {
    if (method == 'google') {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Text(
          'G',
          style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 13),
        ),
      );
    } else if (method == 'phone') {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.phone_iphone_rounded, color: AppColors.accent, size: 14),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.email_outlined, color: AppColors.secondary, size: 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(userProfileProvider);
    final activeUid = currentUser?.uid;

    final otherAccounts = _savedAccounts.where((a) => a.uid != activeUid).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Switch Account', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ResponsiveWebWrapper(
                maxWidth: 700,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currently Active',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),

                    // Currently Signed-In Active Account Highlighted Card
                    if (currentUser != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.container),
                          border: Border.all(color: AppColors.primary, width: 2.0),
                          boxShadow: AppColors.softGlow(AppColors.primary, opacity: 0.15, blur: 14),
                        ),
                        child: Row(
                          children: [
                            if (currentUser.photoURL != null && currentUser.photoURL!.isNotEmpty)
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(currentUser.photoURL!),
                              )
                            else
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  (currentUser.displayName ?? profile.name).isNotEmpty
                                      ? (currentUser.displayName ?? profile.name)[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                                ),
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          currentUser.displayName ?? profile.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
                                            SizedBox(width: 4),
                                            Text(
                                              'Active',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentUser.email ?? currentUser.phoneNumber ?? profile.email ?? 'Signed In',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text('No active session found', style: TextStyle(color: AppColors.textMuted)),

                    const SizedBox(height: 28),

                    // Saved Device Accounts List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Other Device Accounts',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        Text(
                          '${otherAccounts.length} saved',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (otherAccounts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text(
                              'No other accounts saved on this device yet.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: otherAccounts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final account = otherAccounts[index];
                          final name = account.displayName ?? 'Athlete';

                          return AppBouncyTap(
                            onTap: () => _onSelectAccountToSwitch(account),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  if (account.photoUrl != null && account.photoUrl!.isNotEmpty)
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: NetworkImage(account.photoUrl!),
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.surfaceLight,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildMethodIcon(account.signInMethod),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          account.identifier,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                                    onPressed: () => _confirmRemoveAccount(account),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 28),

                    // Add Another Account Button
                    ShineButton(
                      onTap: () => context.go('/onboarding'),
                      backgroundColor: AppColors.surface,
                      borderColor: AppColors.border,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'Add Another Account',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
}

/// Email Re-Auth Bottom Sheet Modal Widget with Shake Feedback & Password Field
class _EmailReAuthModal extends ConsumerStatefulWidget {
  final SavedAccount account;
  final Function(User user) onSuccess;

  const _EmailReAuthModal({required this.account, required this.onSuccess});

  @override
  ConsumerState<_EmailReAuthModal> createState() => _EmailReAuthModalState();
}

class _EmailReAuthModalState extends ConsumerState<_EmailReAuthModal> {
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  bool _isLoading = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_passwordError != null) {
        setState(() => _passwordError = null);
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordError = "Please enter your password";
      });
      _passwordFocusNode.requestFocus();
      _shakeKey.currentState?.shake();
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    try {
      await ref.read(authServiceProvider).signOut();

      final userCred = await ref.read(authServiceProvider).signInWithEmailPassword(
        email: widget.account.identifier,
        password: password,
      );

      if (!mounted) return;
      if (userCred.user != null) {
        widget.onSuccess(userCred.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _passwordError = "Incorrect password. Please try again.";
        } else if (e.code == 'network-request-failed') {
          _passwordError = "No internet connection. Please check your connection.";
        } else {
          _passwordError = e.message ?? "Authentication failed.";
        }
      });
      _passwordFocusNode.requestFocus();
      _shakeKey.currentState?.shake();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _passwordError = "Failed to switch: ${e.toString()}";
      });
      _passwordFocusNode.requestFocus();
      _shakeKey.currentState?.shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accountName = widget.account.displayName ?? widget.account.identifier;

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Switch Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter password for ${widget.account.identifier} ($accountName) to switch.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          ShakeWidget(
            key: _shakeKey,
            child: PasswordField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              labelText: 'Password for ${widget.account.identifier}',
              errorText: _passwordError,
            ),
          ),
          const SizedBox(height: 24),

          ShineButton(
            onTap: _isLoading ? null : _submit,
            backgroundColor: AppColors.primary,
            glowColor: AppColors.primary,
            child: Center(
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Switch Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone Re-Auth Bottom Sheet Modal Widget with OTP Flow
class _PhoneReAuthModal extends ConsumerStatefulWidget {
  final SavedAccount account;
  final Function(User user) onSuccess;

  const _PhoneReAuthModal({required this.account, required this.onSuccess});

  @override
  ConsumerState<_PhoneReAuthModal> createState() => _PhoneReAuthModalState();
}

class _PhoneReAuthModalState extends ConsumerState<_PhoneReAuthModal> {
  late TextEditingController _phoneController;
  final _otpController = TextEditingController();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String? _errorText;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.account.identifier);
  }

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
      setState(() => _errorText = 'Please enter a valid phone number');
      _shakeKey.currentState?.shake();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(authServiceProvider).signOut();

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
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorText = e.message ?? 'Phone verification error';
          });
          _shakeKey.currentState?.shake();
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
        setState(() {
          _isLoading = false;
          _errorText = 'Failed to send OTP: $e';
        });
        _shakeKey.currentState?.shake();
      }
    }
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();
    if (code.length < 6 || _verificationId == null) {
      setState(() => _errorText = 'Please enter valid 6-digit OTP code');
      _shakeKey.currentState?.shake();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

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
        setState(() {
          _isLoading = false;
          _errorText = 'Verification failed. Please check code.';
        });
        _shakeKey.currentState?.shake();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accountName = widget.account.displayName ?? widget.account.identifier;

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
                _isOtpSent ? 'Verify Phone OTP' : 'Switch Phone Account',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isOtpSent
                ? 'Sent 6-digit OTP code to ${widget.account.identifier}'
                : 'Verify phone number for $accountName to switch.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (!_isOtpSent) ...[
            ShakeWidget(
              key: _shakeKey,
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.accent),
                  errorText: _errorText,
                ),
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
            ShakeWidget(
              key: _shakeKey,
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: '6-Digit SMS Code',
                  prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.accent),
                  errorText: _errorText,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                    : const Text('Verify & Switch', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
