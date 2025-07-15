// lib/features/auth/presentation/screens/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';
import '../widgets/auth_button.dart';
import '../../domain/entities/user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  Timer? _verificationCheckTimer;
  Timer? _resendCooldownTimer;
  bool _isResendingEmail = false;
  int _resendCooldown = 0;
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _verificationCheckTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isDisposed && mounted) {
        ref.read(authProvider.notifier).checkEmailVerification();
      } else {
        timer.cancel();
      }
    });
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    
    if (!_isDisposed && mounted) {
      setState(() {
        _resendCooldown = 60;
      });
    }
    
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        timer.cancel();
        _resendCooldownTimer = null;
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_isDisposed || !mounted) return;
    
    setState(() {
      _isResendingEmail = true;
    });

    try {
      await ref.read(authProvider.notifier).sendEmailVerification();
      
      if (!_isDisposed && mounted) {
        _startResendCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent!'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            margin: AppSpacing.screenPaddingAll,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userFriendlyMessage),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: AppSpacing.screenPaddingAll,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Verify Email',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: context.primaryColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: authState.when(
        initial: () => _buildLoadingState(),
        loading: () => _buildLoadingState(),
        emailNotVerified: (user) => _buildVerificationContent(user),
        authenticated: (user) => _buildSuccessState(),
        unauthenticated: () => _buildSessionExpiredState(),
        error: (failure) => _buildErrorState(failure.userFriendlyMessage),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Checking verification status...',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: context.successColor,
              size: 50,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Email Verified!',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Redirecting to home...',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionExpiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.warningColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: context.warningColor,
              size: 50,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Session Expired',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please sign in again.',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: context.errorColor,
                size: 50,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthButton(
              text: 'Try Again',
              onPressed: () {
                ref.read(authProvider.notifier).checkEmailVerification();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationContent(User user) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.email_outlined,
              size: 60,
              color: context.primaryColor,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          Text(
            'Verify Your Email',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Text(
            'We sent a verification email to:',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Container(
            padding: AppSpacing.paddingSymmetricMd,
            decoration: BoxDecoration(
              color: context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              user.email,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Text(
            'Please check your email and click the verification link to continue.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Checking verification status...',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          AuthButton(
            text: _resendCooldown > 0 
                ? 'Resend in ${_resendCooldown}s' 
                : 'Resend Verification Email',
            isLoading: _isResendingEmail,
            onPressed: _resendCooldown > 0 || _isResendingEmail 
                ? () {} 
                : _resendVerificationEmail,
            isSecondary: true,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          AuthButton(
            text: 'I\'ve Verified - Check Now',
            onPressed: () {
              ref.read(authProvider.notifier).checkEmailVerification();
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Text(
            'Didn\'t receive the email? Check your spam folder or try resending.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textTertiaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
