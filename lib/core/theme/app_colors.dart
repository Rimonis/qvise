import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF2196F3); // Material Blue
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF42A5F5);
  static const Color primaryContainerDark = Color(0xFF0D47A1);
  
  static const Color secondary = Color(0xFF4CAF50); // Material Green
  static const Color secondaryLight = Color(0xFF81C784);
  static const Color secondaryDark = Color(0xFF66BB6A);
  static const Color secondaryContainerDark = Color(0xFF1B5E20);
  
  static const Color accent = Color(0xFFFF9800); // Material Orange
  static const Color accentLight = Color(0xFFFFB74D);
  static const Color accentDark = Color(0xFFFFA726);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF388E3C);
  
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningDark = Color(0xFFF57C00);
  
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFE53935);
  static const Color errorContainerDark = Color(0xFF93000A);
  
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF1976D2);

  // Neutral colors - Light theme
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color dividerLight = Color(0xFFBDBDBD);
  
  // Neutral colors - Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color borderDark = Color(0xFF424242);
  static const Color dividerDark = Color(0xFF616161);

  // Text colors - Light theme
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF9E9E9E);
  
  // Text colors - Dark theme
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);
  static const Color textTertiaryDark = Color(0xFF9E9E9E);
  static const Color textDisabledDark = Color(0xFF616161);
  static const Color textHintDark = Color(0xFF757575);

  // Icon colors
  static const Color iconDefault = Color(0xFF757575);
  static const Color iconDefaultDark = Color(0xFFBDBDBD);
  static const Color iconActive = primary;
  static const Color iconActiveDark = primaryDark;

  // Input colors
  static const Color inputFillLight = Color(0xFFF5F5F5);
  static const Color inputFillDark = Color(0xFF2C2C2C);
  static const Color inputBorderLight = Color(0xFFE0E0E0);
  static const Color inputBorderDark = Color(0xFF424242);
  static const Color inputFocusBorderLight = primary;
  static const Color inputFocusBorderDark = primaryDark;

  // Proficiency colors for lessons
  static const Color proficiencyBeginner = Color(0xFFE53935); // Red
  static const Color proficiencyNovice = Color(0xFFFF6F00); // Orange
  static const Color proficiencyIntermediate = Color(0xFFFDD835); // Yellow
  static const Color proficiencyAdvanced = Color(0xFF7CB342); // Light Green
  static const Color proficiencyExpert = Color(0xFF43A047); // Green
  static const Color proficiencyMaster = Color(0xFF1E88E5); // Blue

  // Shadow colors
  static const Color shadowLight = Color(0x1F000000); // 12% black
  static const Color shadowDark = Color(0x3D000000); // 24% black

  // Overlay colors
  static const Color overlayLight = Color(0x0A000000); // 4% black
  static const Color overlayDark = Color(0x1F000000); // 12% black

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper methods
  static Color getProficiencyColor(double proficiency) {
    if (proficiency < 0.17) return proficiencyBeginner;
    if (proficiency < 0.34) return proficiencyNovice;
    if (proficiency < 0.50) return proficiencyIntermediate;
    if (proficiency < 0.67) return proficiencyAdvanced;
    if (proficiency < 0.84) return proficiencyExpert;
    return proficiencyMaster;
  }

  static String getProficiencyLabel(double proficiency) {
    if (proficiency < 0.17) return 'Beginner';
    if (proficiency < 0.34) return 'Novice';
    if (proficiency < 0.50) return 'Intermediate';
    if (proficiency < 0.67) return 'Advanced';
    if (proficiency < 0.84) return 'Expert';
    return 'Master';
  }
}