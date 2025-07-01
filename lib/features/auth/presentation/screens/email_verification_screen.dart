import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';
import '../widgets/auth_button.dart';
import '../../domain/entities/user.dart';

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
    // Start periodic check for email verification
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Cancel both timers to prevent setState() after dispose
    _verificationCheckTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Check if widget is still mounted before calling ref.read()
      if (!_isDisposed && mounted) {
        ref.read(authProvider.notifier).checkEmailVerification();
      } else {
        timer.cancel();
      }
    });
  }

  void _startResendCooldown() {
    // Cancel existing timer if running
    _resendCooldownTimer?.cancel();
    
    if (!_isDisposed && mounted) {
      setState(() {
        _resendCooldown = 60; // 60 seconds cooldown
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
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: authState.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking verification status...'),
            ],
          ),
        ),
        emailNotVerified: (user) => _buildVerificationContent(user),
        authenticated: (user) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 16),
              Text(
                'Email Verified!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Redirecting to home...'),
            ],
          ),
        ),
        unauthenticated: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.orange, size: 80),
              SizedBox(height: 16),
              Text(
                'Session Expired',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please sign in again.'),
            ],
          ),
        ),
        error: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 80),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                AuthButton(
                  text: 'Try Again',
                  onPressed: () {
                    ref.read(authProvider.notifier).checkEmailVerification();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationContent(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Email icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 60,
              color: Colors.blue,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          const Text(
            'Verify Your Email',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'We sent a verification email to:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Email address
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user.email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Instructions
          Text(
            'Please check your email and click the verification link to continue.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Auto-checking indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Checking verification status...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Resend email button
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
          
          const SizedBox(height: 16),
          
          // Manual check button
          AuthButton(
            text: 'I\'ve Verified - Check Now',
            onPressed: () {
              ref.read(authProvider.notifier).checkEmailVerification();
            },
          ),
          
          const SizedBox(height: 24),
          
          // Help text
          Text(
            'Didn\'t receive the email? Check your spam folder or try resending.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}