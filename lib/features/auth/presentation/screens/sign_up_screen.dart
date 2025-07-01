import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/utils/password_validator.dart';

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
    
    // Listen to password changes to update strength indicator
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
      error: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      },
      authenticated: (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.displayName ?? user.email}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      },
      emailNotVerified: (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email to continue'),
            backgroundColor: Colors.orange,
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
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
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
                      // Check for valid name characters
                      if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
                        return 'Name contains invalid characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                    const SizedBox(height: 8),
                    _buildPasswordStrengthIndicator(),
                  ],
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AuthButton(
                    text: 'Continue with Google',
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    isSecondary: true,
                    isLoading: isLoading,
                    onPressed: isLoading ? () {} : () {
                      ref.read(authProvider.notifier).signInWithGoogle();
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: isLoading ? null : () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Privacy notice
                  Text(
                    'By signing up, you agree to our Terms of Service and Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Creating your account...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 12,
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}