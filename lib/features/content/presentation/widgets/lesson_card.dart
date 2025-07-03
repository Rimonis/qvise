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
    final proficiencyColor = Color(int.parse(lesson.proficiencyColor.replaceAll('#', '0xFF')));
    final isDue = lesson.isReviewDue;
    
    return Card(
      elevation: isDue ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: isDue
            ? BorderSide(color: AppColors.warning.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: AppSpacing.paddingAllMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.displayTitle,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.layers,
                              size: AppSpacing.iconSm,
                              color: context.textSecondaryColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Stage ${lesson.reviewStage}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            if (!lesson.isSynced) ...[
                              const Icon(
                                Icons.cloud_off,
                                size: AppSpacing.iconSm,
                                color: AppColors.warningDark,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Not synced',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error, size: AppSpacing.iconSm),
                              SizedBox(width: AppSpacing.sm),
                              Text('Delete', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, color: context.iconColor),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Review status
              Container(
                padding: AppSpacing.paddingSymmetricMd,
                decoration: BoxDecoration(
                  color: isDue 
                    ? AppColors.warning.withValues(alpha: 0.1) 
                    : context.surfaceVariantColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: isDue 
                      ? AppColors.warning.withValues(alpha: 0.3) 
                      : context.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDue ? Icons.alarm : Icons.schedule,
                          size: AppSpacing.iconSm,
                          color: isDue ? AppColors.warningDark : context.textSecondaryColor,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          lesson.reviewStatus,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDue ? AppColors.warningDark : context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: AppSpacing.paddingSymmetricSm,
                      decoration: BoxDecoration(
                        color: proficiencyColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      child: Text(
                        '${(lesson.proficiency * 100).toInt()}%',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: proficiencyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Last reviewed
              if (lesson.lastReviewedAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: AppSpacing.iconSm,
                      color: context.textTertiaryColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Last reviewed: ${_formatDate(lesson.lastReviewedAt!)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}