import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class EmptyContentWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool showOfflineMessage;
  
  const EmptyContentWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.showOfflineMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: context.primaryColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (showOfflineMessage) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingSymmetricSm,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: AppSpacing.iconSm,
                      color: AppColors.warningDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Internet connection required',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.warningDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add),
                label: Text(
                  buttonText!,
                  style: context.textTheme.labelLarge,
                ),
                style: ElevatedButton.styleFrom(
                  padding: AppSpacing.paddingSymmetricMd,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
