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
    final proficiencyColor = Color(int.parse(topic.proficiencyColor.replaceAll('#', '0xFF')));
    
    return Card(
      margin: AppSpacing.paddingSymmetricSm,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: AppSpacing.paddingSymmetricMd,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: proficiencyColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.topic,
                color: proficiencyColor,
                size: AppSpacing.iconLg,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: AppSpacing.paddingSymmetricSm,
                    decoration: BoxDecoration(
                      color: proficiencyColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Text(
                      '${(topic.proficiency * 100).toInt()}%',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          topic.name,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${topic.lessonCount} ${topic.lessonCount == 1 ? 'lesson' : 'lessons'}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              topic.proficiencyLabel,
              style: context.textTheme.bodySmall?.copyWith(
                color: proficiencyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.access_time,
                  size: AppSpacing.iconSm,
                  color: context.textTertiaryColor,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatLastStudied(topic.lastStudied),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: AppSpacing.sm),
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
                icon: const Icon(Icons.more_vert, size: AppSpacing.iconSm),
              ),
            ] else
              Icon(
                Icons.chevron_right,
                color: context.iconColor.withValues(alpha: 0.5),
              ),
          ],
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
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }
}