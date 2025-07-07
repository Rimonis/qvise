// lib/features/content/presentation/widgets/lesson_card.dart

import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDue = lesson.isDue;
    final daysTillDue = lesson.daysTillNextReview;

    return Card(
      elevation: isDue ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: isDue
            ? BorderSide(color: context.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: AppSpacing.paddingAllMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.displayTitle,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Text(
                        'DUE',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _buildStatChip(
                    context,
                    Icons.layers,
                    '${lesson.flashcardCount} cards',
                    context.textSecondaryColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatChip(
                    context,
                    Icons.repeat,
                    '${lesson.reviewStage} reviews',
                    context.textSecondaryColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatChip(
                    context,
                    Icons.timer,
                    _getTimeStatus(daysTillDue),
                    _getTimeStatusColor(daysTillDue),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proficiency',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSmall),
                          child: LinearProgressIndicator(
                            value: lesson.proficiency,
                            backgroundColor: context.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProficiencyColor(lesson.proficiency),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${(lesson.proficiency * 100).toInt()}%',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: _getProficiencyColor(lesson.proficiency),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.error,
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      tooltip: 'Delete lesson',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeStatus(int daysTillDue) {
    if (daysTillDue < 0) {
      return '${-daysTillDue}d overdue';
    } else if (daysTillDue == 0) {
      return 'Due today';
    } else {
      return 'Due in ${daysTillDue}d';
    }
  }

  Color _getTimeStatusColor(int daysTillDue) {
    if (daysTillDue < 0) return AppColors.error;
    if (daysTillDue == 0) return AppColors.warning;
    return AppColors.success;
  }

  Color _getProficiencyColor(double proficiency) {
    if (proficiency >= 0.8) return AppColors.success;
    if (proficiency >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}