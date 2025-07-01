import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // Font families
  static String get primaryFontFamily => GoogleFonts.inter().fontFamily!;
  static String get headingFontFamily => GoogleFonts.poppins().fontFamily!;
  static String get monospaceFontFamily => GoogleFonts.firaCode().fontFamily!;

  // Text theme for light mode
  static TextTheme get textTheme {
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        color: AppColors.textPrimary,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.textPrimary,
      ),

      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.textPrimary,
      ),

      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.textSecondary,
      ),

      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
    );
  }

  // Text theme for dark mode
  static TextTheme get textThemeDark {
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge!.copyWith(color: AppColors.textPrimaryDark),
      displayMedium: textTheme.displayMedium!.copyWith(color: AppColors.textPrimaryDark),
      displaySmall: textTheme.displaySmall!.copyWith(color: AppColors.textPrimaryDark),
      headlineLarge: textTheme.headlineLarge!.copyWith(color: AppColors.textPrimaryDark),
      headlineMedium: textTheme.headlineMedium!.copyWith(color: AppColors.textPrimaryDark),
      headlineSmall: textTheme.headlineSmall!.copyWith(color: AppColors.textPrimaryDark),
      titleLarge: textTheme.titleLarge!.copyWith(color: AppColors.textPrimaryDark),
      titleMedium: textTheme.titleMedium!.copyWith(color: AppColors.textPrimaryDark),
      titleSmall: textTheme.titleSmall!.copyWith(color: AppColors.textPrimaryDark),
      bodyLarge: textTheme.bodyLarge!.copyWith(color: AppColors.textPrimaryDark),
      bodyMedium: textTheme.bodyMedium!.copyWith(color: AppColors.textPrimaryDark),
      bodySmall: textTheme.bodySmall!.copyWith(color: AppColors.textSecondaryDark),
      labelLarge: textTheme.labelLarge!.copyWith(color: AppColors.textPrimaryDark),
      labelMedium: textTheme.labelMedium!.copyWith(color: AppColors.textSecondaryDark),
      labelSmall: textTheme.labelSmall!.copyWith(color: AppColors.textSecondaryDark),
    );
  }

  // Custom text styles (reusable across the app)
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.43,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.6,
    color: AppColors.textTertiary,
  );

  static TextStyle get code => GoogleFonts.firaCode(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.43,
  );

  static TextStyle get link => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  // Specific use case styles - using the base text theme styles
  static TextStyle get appBarTitle => textTheme.headlineSmall!;

  static TextStyle get cardTitle => textTheme.titleMedium!;

  static TextStyle get cardSubtitle => textTheme.bodySmall!;

  static TextStyle get listItemTitle => textTheme.bodyLarge!;

  static TextStyle get listItemSubtitle => textTheme.bodyMedium!.copyWith(
    color: AppColors.textSecondary,
  );

  static TextStyle get inputLabel => textTheme.labelLarge!;

  static TextStyle get inputText => textTheme.bodyLarge!;

  static TextStyle get inputHint => textTheme.bodyLarge!.copyWith(
    color: AppColors.textHint,
  );

  static TextStyle get inputError => textTheme.bodySmall!.copyWith(
    color: AppColors.error,
  );

  static TextStyle get snackbarText => textTheme.bodyMedium!.copyWith(
    color: Colors.white,
  );

  static TextStyle get tabLabel => textTheme.labelLarge!;

  static TextStyle get chipLabel => textTheme.labelMedium!;

  static TextStyle get tooltipText => textTheme.bodySmall!;

  static TextStyle get badgeText => textTheme.labelSmall!.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  // FIX: Add the missing static getters here
  static TextStyle get headlineSmall => textTheme.headlineSmall!;
  static TextStyle get bodyMedium => textTheme.bodyMedium!;
  static TextStyle get labelMedium => textTheme.labelMedium!;
  static TextStyle get bodyLarge => textTheme.bodyLarge!;
}