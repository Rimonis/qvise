import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// Extension on BuildContext for easy theme access
extension ThemeExtensions on BuildContext {
  // Theme data
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  // Brightness
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLightMode => theme.brightness == Brightness.light;
  
  // Colors - Primary
  Color get primaryColor => colorScheme.primary;
  Color get primaryContainerColor => colorScheme.primaryContainer;
  Color get onPrimaryColor => colorScheme.onPrimary;
  
  // Colors - Secondary
  Color get secondaryColor => colorScheme.secondary;
  Color get secondaryContainerColor => colorScheme.secondaryContainer;
  Color get onSecondaryColor => colorScheme.onSecondary;
  
  // Colors - Surface
  Color get backgroundColor => colorScheme.surface;
  Color get surfaceColor => colorScheme.surface;
  Color get surfaceVariantColor => colorScheme.surfaceContainerHighest;
  
  // Colors - Status
  Color get errorColor => colorScheme.error;
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get infoColor => AppColors.info;
  
  // Text colors
  Color get textPrimaryColor => isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textTertiaryColor => isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary;
  Color get textDisabledColor => isDarkMode ? AppColors.textDisabledDark : AppColors.textDisabled;
  
  // Border colors
  Color get borderColor => isDarkMode ? AppColors.borderDark : AppColors.borderLight;
  Color get dividerColor => isDarkMode ? AppColors.dividerDark : AppColors.dividerLight;
  
  // Icon colors
  Color get iconColor => isDarkMode ? AppColors.iconDefaultDark : AppColors.iconDefault;
  Color get iconActiveColor => isDarkMode ? AppColors.iconActiveDark : AppColors.iconActive;
  
  // Media query shortcuts
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  
  // Responsive helpers
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;
  
  // Safe area
  double get safeAreaTop => padding.top;
  double get safeAreaBottom => padding.bottom;
  double get safeAreaLeft => padding.left;
  double get safeAreaRight => padding.right;
}

// Custom theme widgets
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      elevation: elevation,
      margin: margin ?? EdgeInsets.zero,
      child: Padding(
        padding: padding ?? AppSpacing.cardContentPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: card,
      );
    }

    return card;
  }
}

class ThemedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isOutlined;
  final IconData? icon;
  final Color? color;
  final double? width;

  const ThemedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isOutlined = false,
    this.icon,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconSm),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(text),
            ],
          );

    final style = isSecondary
        ? TextButton.styleFrom(foregroundColor: color)
        : isOutlined
            ? OutlinedButton.styleFrom(foregroundColor: color)
            : ElevatedButton.styleFrom(backgroundColor: color);

    Widget button;
    if (isSecondary) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    } else if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}

class ThemedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool readOnly;

  const ThemedTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      style: AppTypography.inputText,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffix,
      ),
    );
  }
}

// Usage example widget
class ThemeUsageExample extends StatelessWidget {
  const ThemeUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Theme Example',
          style: AppTypography.appBarTitle,
        ),
      ),
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Using theme colors
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: context.primaryColor),
              ),
              child: Text(
                'Primary colored container',
                style: AppTypography.bodyLarge.copyWith(
                  color: context.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Using themed card
            ThemedCard(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Title',
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Card subtitle with secondary text color',
                    style: AppTypography.cardSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Using themed buttons
            Row(
              children: [
                Expanded(
                  child: ThemedButton(
                    text: 'Primary',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ThemedButton(
                    text: 'Secondary',
                    onPressed: () {},
                    isSecondary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Using spacing
            Text(
              'Consistent spacing throughout the app',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            
            // Responsive design
            if (context.isMobile)
              const Text('Mobile layout')
            else if (context.isTablet)
              const Text('Tablet layout')
            else
              const Text('Desktop layout'),
          ],
        ),
      ),
    );
  }
}