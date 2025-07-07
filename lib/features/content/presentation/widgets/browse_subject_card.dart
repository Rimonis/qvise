// lib/features/content/presentation/widgets/browse_subject_card.dart

import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/subject.dart';

class BrowseSubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const BrowseSubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: AppSpacing.paddingAllMd,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.school,
                  color: context.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          Icons.topic,
                          '${subject.topicCount} topics',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildInfoChip(
                          context,
                          Icons.book,
                          '${subject.lessonCount} lessons',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LinearProgressIndicator(
                      value: subject.proficiency,
                      backgroundColor: context.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProficiencyColor(subject.proficiency),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Delete subject',
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.textTertiaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.textSecondaryColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProficiencyColor(double proficiency) {
    if (proficiency >= 0.8) return AppColors.success;
    if (proficiency >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}