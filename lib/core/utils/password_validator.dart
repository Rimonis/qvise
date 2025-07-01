import 'package:flutter/material.dart';

class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 128;
  
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    if (password.length > maxLength) {
      return 'Password must be less than $maxLength characters';
    }
    
    final List<String> errors = [];
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('uppercase letter');
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('lowercase letter');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('number');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('special character');
    }
    
    if (errors.isNotEmpty) {
      final errorList = errors.join(', ');
      return 'Password must contain at least one $errorList';
    }
    
    // Check for common weak passwords
    final weakPasswords = [
      'password', 'password123', '12345678', 'qwerty123',
      'admin123', 'letmein', 'welcome123', 'monkey123'
    ];
    
    if (weakPasswords.contains(password.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }
    
    return null;
  }
  
  static double getStrength(String password) {
    double strength = 0.0;
    
    if (password.isEmpty) return strength;
    
    // Length score
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    if (password.length >= 16) strength += 0.1;
    
    // Character variety score
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.125;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.125;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.125;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.125;
    
    return strength.clamp(0.0, 1.0);
  }
  
  static String getStrengthText(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.5) return 'Fair';
    if (strength < 0.7) return 'Good';
    if (strength < 0.9) return 'Strong';
    return 'Very Strong';
  }
  
  static Color getStrengthColor(double strength) {
    if (strength < 0.3) return const Color(0xFFD32F2F); // Red
    if (strength < 0.5) return const Color(0xFFF57C00); // Orange
    if (strength < 0.7) return const Color(0xFFFBC02D); // Yellow
    if (strength < 0.9) return const Color(0xFF689F38); // Light Green
    return const Color(0xFF388E3C); // Green
  }
}