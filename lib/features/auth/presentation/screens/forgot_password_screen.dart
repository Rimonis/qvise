import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final resetPassword = await ref.read(resetPasswordProvider.future);
      final result = await resetPassword(_emailController.text.trim());

      result.fold(
        (failure) {
          if (!_isDisposed && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: context.errorColor,
                behavior: SnackBarBehavior.floating,
                margin: AppSpacing.screenPaddingAll,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
            );
          }
        },
        (_) {
          if (!_isDisposed && mounted) {
            setState(() {
              _emailSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Password reset email sent successfully!'),
                backgroundColor: context.successColor,
                behavior: SnackBarBehavior.floating,
                margin: AppSpacing.screenPaddingAll,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPaddingAll,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(),
                const SizedBox(height: AppSpacing.xxl),
                
                if (!_emailSent) ...[
                  AuthTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    showClearButton: true,
                    maxLength: 100,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  AuthButton(
                    text: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? () {} : _sendPasswordResetEmail,
                  ),
                ] else ...[
                  _buildSuccessSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInstructionsSection(),
                  const SizedBox(height: AppSpacing.md),
                  _buildHelpText(),
                  const SizedBox(height: AppSpacing.xl),
                  
                  AuthButton(
                    text: 'Send Another Email',
                    isSecondary: true,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? () {} : () {
                      setState(() {
                        _emailSent = false;
                        _emailController.clear();
                      });
                    },
                  ),
                ],
                
                const SizedBox(height: AppSpacing.md),
                
                AuthButton(
                  text: 'Back to Sign In',
                  isSecondary: !_emailSent,
                  onPressed: () {
                    context.pop();
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                if (!_emailSent) _buildRememberPasswordText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _emailSent 
              ? context.successColor.withValues(alpha: 0.1)
              : context.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
            size: 50,
            color: _emailSent ? context.successColor : context.primaryColor,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        Text(
          _emailSent ? 'Check Your Email' : 'Forgot Password?',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        
        Text(
          _emailSent
              ? 'We\'ve sent a password reset link to ${_emailController.text}'
              : 'Enter your email address and we\'ll send you a link to reset your password.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessSection() {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: context.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: context.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: context.successColor,
            size: AppSpacing.iconLg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Password reset email sent successfully!',
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColors.successDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: context.infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What to do next:',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInstructionItem('1', 'Check your email inbox'),
          _buildInstructionItem('2', 'Click the reset link in the email'),
          _buildInstructionItem('3', 'Create a new password'),
          _buildInstructionItem('4', 'Sign in with your new password'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: context.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Text(
      'Didn\'t receive the email? Check your spam folder or try again.',
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textSecondaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRememberPasswordText() {
    return Text(
      'Remember your password?',
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textTertiaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }
}