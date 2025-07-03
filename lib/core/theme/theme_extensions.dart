// Enhanced theme_extensions.dart with additional utilities
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
  Color get surfaceVariantColor => isDarkMode ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
  
  // Colors - Status (Enhanced)
  Color get errorColor => colorScheme.error;
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get infoColor => AppColors.info;
  
  // Text colors with proper fallbacks
  Color get textPrimaryColor => isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textTertiaryColor => isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary;
  Color get textDisabledColor => isDarkMode ? AppColors.textDisabledDark : AppColors.textDisabled;
  
  // Border and divider colors
  Color get borderColor => isDarkMode ? AppColors.borderDark : AppColors.borderLight;
  Color get dividerColor => isDarkMode ? AppColors.dividerDark : AppColors.dividerLight;
  
  // Icon colors
  Color get iconColor => isDarkMode ? AppColors.iconDefaultDark : AppColors.iconDefault;
  Color get iconActiveColor => isDarkMode ? AppColors.iconActiveDark : AppColors.iconActive;
  
  // ADDED: Semantic color helpers
  Color get cardBackgroundColor => surfaceColor;
  Color get scaffoldBackgroundColor => backgroundColor;
  Color get appBarBackgroundColor => surfaceColor;
  Color get bottomNavBackgroundColor => surfaceColor;
  
  // ADDED: Status colors with proper contrast
  Color get successContainerColor => AppColors.success.withValues(alpha: 0.1);
  Color get warningContainerColor => AppColors.warning.withValues(alpha: 0.1);
  Color get errorContainerColor => AppColors.error.withValues(alpha: 0.1);
  Color get infoContainerColor => AppColors.info.withValues(alpha: 0.1);
  
  // ADDED: Interactive state colors
  Color get hoverColor => primaryColor.withValues(alpha: 0.04);
  Color get focusColor => primaryColor.withValues(alpha: 0.12);
  Color get pressedColor => primaryColor.withValues(alpha: 0.16);
  Color get selectedColor => primaryColor.withValues(alpha: 0.08);
  
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
}

// ADDED: Enhanced themed widgets with better integration
class ThemedScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  const ThemedScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color ?? context.cardBackgroundColor,
      elevation: elevation ?? 1,
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Padding(
        padding: padding ?? AppSpacing.cardContentPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMedium),
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
  final ButtonStyle? style;

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
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSecondary || isOutlined ? context.primaryColor : Colors.white,
              ),
            ),
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

    final buttonStyle = style ?? (isSecondary
        ? TextButton.styleFrom(
            foregroundColor: color ?? context.primaryColor,
            backgroundColor: context.surfaceColor,
          )
        : isOutlined
            ? OutlinedButton.styleFrom(
                foregroundColor: color ?? context.primaryColor,
                side: BorderSide(color: color ?? context.primaryColor),
              )
            : ElevatedButton.styleFrom(
                backgroundColor: color ?? context.primaryColor,
                foregroundColor: Colors.white,
              ));

    Widget button;
    if (isSecondary) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      );
    } else if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}

class ThemedContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const ThemedContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.surfaceColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMedium),
        border: border ?? Border.all(color: context.borderColor),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

// ADDED: Status message containers
class StatusContainer extends StatelessWidget {
  final String message;
  final StatusType type;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatusContainer({
    super.key,
    required this.message,
    required this.type,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData defaultIcon;

    switch (type) {
      case StatusType.success:
        backgroundColor = context.successContainerColor;
        textColor = AppColors.successDark;
        iconColor = AppColors.success;
        defaultIcon = Icons.check_circle;
        break;
      case StatusType.warning:
        backgroundColor = context.warningContainerColor;
        textColor = AppColors.warningDark;
        iconColor = AppColors.warning;
        defaultIcon = Icons.warning;
        break;
      case StatusType.error:
        backgroundColor = context.errorContainerColor;
        textColor = AppColors.errorDark;
        iconColor = AppColors.error;
        defaultIcon = Icons.error;
        break;
      case StatusType.info:
        backgroundColor = context.infoContainerColor;
        textColor = AppColors.infoDark;
        iconColor = AppColors.info;
        defaultIcon = Icons.info;
        break;
    }

    Widget container = Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? defaultIcon,
            color: iconColor,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}

enum StatusType { success, warning, error, info }