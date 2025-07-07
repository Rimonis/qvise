// lib/features/content/presentation/widgets/topic_tile.dart

import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/topic.dart';

class TopicTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TopicTile({
    super.key,
    required this.topic,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.topic,
                  color: context.secondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.book,
                          size: 16,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${topic.lessonCount} lessons',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _getProficiencyColor(topic.proficiency)
                                .withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          child: Text(
                            '${(topic.proficiency * 100).toInt()}%',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: _getProficiencyColor(topic.proficiency),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Delete topic',
                ),
              ],
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

  Color _getProficiencyColor(double proficiency) {
    if (proficiency >= 0.8) return AppColors.success;
    if (proficiency >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}