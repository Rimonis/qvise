// lib/features/auth/presentation/screens/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  double _passwordStrength = 0.0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _updatePasswordStrength() {
    if (_isDisposed) return;
    
    final strength = PasswordValidator.getStrength(_passwordController.text);
    if (strength != _passwordStrength) {
      setState(() {
        _passwordStrength = strength;
      });
    }
  }

  void _handleAuthState(AuthState state) {
    if (_isDisposed || !mounted) return;
    
    state.maybeWhen(
      error: (AppFailure failure) {
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
      },
      authenticated: (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.displayName ?? user.email}!'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            margin: AppSpacing.screenPaddingAll,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
        Navigator.pop(context);
      },
      emailNotVerified: (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please verify your email to continue'),
            backgroundColor: context.warningColor,
            behavior: SnackBarBehavior.floating,
            margin: AppSpacing.screenPaddingAll,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
    
    ref.listen(authProvider, (previous, current) {
      if (!_isDisposed && mounted) {
        _handleAuthState(current);
      }
    });

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: AppSpacing.screenPaddingAll,
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  
                  _buildHeroSection(),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  AuthTextField(
                    controller: _nameController,
                    hintText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    maxLength: 50,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
                        return 'Name contains invalid characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  AuthTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
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
                  const SizedBox(height: AppSpacing.md),
                  
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    showObscureToggle: true,
                    prefixIcon: Icons.lock_outline,
                    maxLength: 128,
                    validator: PasswordValidator.validate,
                  ),
                  
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildPasswordStrengthIndicator(),
                  ],
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  AuthTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    showObscureToggle: true,
                    prefixIcon: Icons.lock_outline,
                    maxLength: 128,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  AuthButton(
                    text: 'Sign Up',
                    isLoading: isLoading,
                    onPressed: isLoading ? () {} : () {
                      if (_formKey.currentState!.validate()) {
                        ref.read(authProvider.notifier).signUpWithEmailPassword(
                          _emailController.text.trim(),
                          _passwordController.text,
                          _nameController.text.trim(),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  _buildDivider(),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  AuthButton(
                    text: 'Continue with Google',
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    isSecondary: true,
                    isLoading: isLoading,
                    onPressed: isLoading ? () {} : () {
                      ref.read(authProvider.notifier).signInWithGoogle();
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  _buildSignInLink(isLoading),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  _buildPrivacyNotice(),
                  
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          
          if (isLoading) _buildLoadingOverlay(),
        ],
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
            color: context.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_add_outlined,
            size: 50,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        Text(
          'Create Account',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Sign up to get started',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final strengthText = PasswordValidator.getStrengthText(_passwordStrength);
    final strengthColor = PasswordValidator.getStrengthColor(_passwordStrength);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            Text(
              strengthText,
              style: context.textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: context.surfaceVariantColor,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: context.dividerColor),
        ),
        Padding(
          padding: AppSpacing.paddingHorizontalMd,
          child: Text(
            'OR',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: context.dividerColor),
        ),
      ],
    );
  }

  Widget _buildSignInLink(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: context.primaryColor,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Sign In',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyNotice() {
    return Text(
      'By signing up, you agree to our Terms of Service and Privacy Policy',
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textTertiaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: context.backgroundColor.withValues(alpha: 0.8),
      child: Center(
        child: Card(
          color: context.cardBackgroundColor,
          child: Padding(
            padding: AppSpacing.paddingAllXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Creating your account...',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor,
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
