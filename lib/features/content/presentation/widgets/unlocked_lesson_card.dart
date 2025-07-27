// lib/features/content/presentation/widgets/unlocked_lesson_card.dart
import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';

class UnlockedLessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // The onDelete callback is now correctly added

  const UnlockedLessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    this.onDelete, // Added to the constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: BorderSide(color: context.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          child: Row(
            children: [
              // Icon representing the lesson/content
              Container(
                padding: AppSpacing.paddingAllMd,
                decoration: BoxDecoration(
                  color: context.surfaceVariantColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note,
                  color: context.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Lesson details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.displayTitle,
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${lesson.subjectName} > ${lesson.topicName}',
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: context.textSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildStatChip(
                          context,
                          '${lesson.flashcardCount}',
                          'Cards',
                          Icons.style_outlined,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildStatChip(
                          context,
                          '${(lesson.proficiency * 100).toInt()}%',
                          'Mastery',
                          Icons.psychology_alt_outlined,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Trailing icons (edit and delete)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  // The delete button is now correctly placed and functional
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: context.textTertiaryColor,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete Lesson',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: context.textSecondaryColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}