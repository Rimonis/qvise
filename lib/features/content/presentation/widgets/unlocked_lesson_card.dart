// lib/features/content/presentation/widgets/unlocked_lesson_card.dart
import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';

class UnlockedLessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const UnlockedLessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // A lesson is considered "Empty" if it has no content.
    final bool isEmpty = lesson.flashcardCount == 0 && lesson.fileCount == 0 && lesson.noteCount == 0;

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
              // Icon representing the lesson
              Container(
                padding: AppSpacing.paddingAllMd,
                decoration: BoxDecoration(
                  color: context.surfaceVariantColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_sharp,
                  color: context.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Lesson Title, Path, and Content Counts
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
                    // ## NEW: Content count chips ##
                    Row(
                      children: [
                        _buildStatChip(
                          context,
                          '${lesson.flashcardCount}',
                          Icons.style_outlined, // Flashcards
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildStatChip(
                          context,
                          '${lesson.fileCount}',
                          Icons.attach_file_outlined, // Files
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildStatChip(
                          context,
                          '${lesson.noteCount}',
                          Icons.note_alt_outlined, // Notes
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // ## NEW: Status indicator ##
                    _buildStatusIndicator(context, isEmpty),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Trailing Action Icons
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
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

  // A small, reusable widget for displaying content counts.
  Widget _buildStatChip(BuildContext context, String value, IconData icon) {
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
        ],
      ),
    );
  }

  // A new widget to show if the lesson is empty or ready.
  Widget _buildStatusIndicator(BuildContext context, bool isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isEmpty
            ? Colors.grey.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmpty ? Icons.circle_outlined : Icons.check_circle,
            size: 14,
            color: isEmpty ? Colors.grey[600] : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isEmpty ? 'Empty' : 'Ready to Lock',
            style: context.textTheme.labelSmall?.copyWith(
              color: isEmpty ? Colors.grey[700] : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}