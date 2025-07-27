// lib/core/shell and tabs/analytics_tab.dart
import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

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
                Icons.analytics,
                size: 64,
                color: context.primaryColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Analytics Coming Soon',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Track your learning progress, review patterns, and performance metrics.',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: context.surfaceVariantColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: context.primaryColor,
                        size: AppSpacing.iconSm,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Planned Features:',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureItem(context, 'Learning streaks and study time'),
                      _buildFeatureItem(context, 'Review success rates'),
                      _buildFeatureItem(context, 'Subject proficiency trends'),
                      _buildFeatureItem(context, 'Weekly and monthly reports'),
                      _buildFeatureItem(context, 'Performance comparisons'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: AppSpacing.iconXs,
            color: context.primaryColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}