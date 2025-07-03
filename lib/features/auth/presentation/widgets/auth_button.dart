import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Icon? icon;
  final bool isSecondary;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? context.surfaceColor : context.primaryColor,
          foregroundColor: isSecondary ? context.textPrimaryColor : Colors.white,
          side: isSecondary ? BorderSide(color: context.borderColor) : null,
          elevation: isSecondary ? 0 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          disabledBackgroundColor: context.textDisabledColor.withValues(alpha: 0.12),
          disabledForegroundColor: context.textDisabledColor,
        ),
        child: isLoading
            ? SizedBox(
                height: AppSpacing.iconSm,
                width: AppSpacing.iconSm,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSecondary ? context.primaryColor : Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Text(
                    text,
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}