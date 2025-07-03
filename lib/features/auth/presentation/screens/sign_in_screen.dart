import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'sign_up_screen.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthState(AuthState state) {
    if (_isDisposed || !mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      
      state.maybeWhen(
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
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
              content: Text('Welcome back, ${user.displayName ?? user.email.split('@')[0]}!'),
              backgroundColor: context.successColor,
              behavior: SnackBarBehavior.floating,
              margin: AppSpacing.screenPaddingAll,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
          );
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
    });
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
          'Sign In',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: context.appBarBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
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
                    const SizedBox(height: AppSpacing.md),
                    
                    AuthTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      showObscureToggle: true,
                      prefixIcon: Icons.lock_outline,
                      maxLength: 128,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () {
                          context.push(RouteNames.forgotPassword);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: context.primaryColor,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: context.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    AuthButton(
                      text: 'Sign In',
                      isLoading: isLoading,
                      onPressed: isLoading ? () {} : () {
                        FocusScope.of(context).unfocus();
                        
                        if (_formKey.currentState!.validate()) {
                          ref.read(authProvider.notifier).signInWithEmailPassword(
                            _emailController.text.trim(),
                            _passwordController.text,
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
                    
                    _buildSignUpLink(isLoading),
                  ],
                ),
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
            Icons.lock_outline,
            size: 50,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        Text(
          'Welcome Back',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Sign in to your account',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
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

  Widget _buildSignUpLink(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignUpScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: context.primaryColor,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Sign Up',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
        ),
      ],
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
                  'Signing you in...',
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