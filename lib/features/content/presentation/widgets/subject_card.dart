import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/subject.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final proficiencyColor = Color(int.parse(subject.proficiencyColor.replaceAll('#', '0xFF')));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: proficiencyColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Icon(
                      Icons.school,
                      color: proficiencyColor,
                      size: AppSpacing.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${subject.topicCount} topics • ${subject.lessonCount} lessons',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
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
              
              // Proficiency indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Proficiency',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '${(subject.proficiency * 100).toInt()}%',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: proficiencyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    child: LinearProgressIndicator(
                      value: subject.proficiency,
                      minHeight: 8,
                      backgroundColor: context.surfaceVariantColor,
                      valueColor: AlwaysStoppedAnimation<Color>(proficiencyColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subject.proficiencyLabel,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: proficiencyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Last studied
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: AppSpacing.iconSm,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Last studied: ${_formatLastStudied(subject.lastStudied)}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatLastStudied(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}