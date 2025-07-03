import 'package:flutter/material.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/lesson.dart';

class DueLessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const DueLessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDue = lesson.isReviewDue;
    final proficiencyColor =
        Color(int.parse(lesson.proficiencyColor.replaceAll('#', '0xFF')));

    return Card(
      elevation: isDue ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDue
            ? BorderSide(color: context.warningColor.withOpacity(0.6), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tags
              Row(
                children: [
                  // Subject tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      lesson.subjectName,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Topic tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.secondaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      lesson.topicName,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.secondaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Day created
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.surfaceVariantColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lesson.dayCreated,
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lesson title
              Text(
                lesson.displayTitle,
                style: context.textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Review stage bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Review Stage ${lesson.reviewStage}/5',
                        style: context.textTheme.bodyMedium,
                      ),
                      Text(
                        '${(lesson.reviewStageProgress * 100).toInt()}%',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: proficiencyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: lesson.reviewStageProgress,
                      minHeight: 6,
                      backgroundColor: context.dividerColor,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(proficiencyColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content counts and review status
              Row(
                children: [
                  // Content indicators
                  if (lesson.flashcardCount > 0) ...[
                    _buildContentIndicator(
                      context,
                      Icons.style,
                      lesson.flashcardCount.toString(),
                      'Flashcards',
                      context.primaryColor,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (lesson.fileCount > 0) ...[
                    _buildContentIndicator(
                      context,
                      Icons.attachment,
                      lesson.fileCount.toString(),
                      'Files',
                      context.successColor,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (lesson.noteCount > 0) ...[
                    _buildContentIndicator(
                      context,
                      Icons.note,
                      lesson.noteCount.toString(),
                      'Notes',
                      context.warningColor,
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),

                  // Review status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDue
                          ? context.warningColor.withOpacity(0.1)
                          : context.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDue
                            ? context.warningColor.withOpacity(0.3)
                            : context.infoColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDue ? Icons.alarm : Icons.schedule,
                          size: 14,
                          color: isDue
                              ? context.warningColor
                              : context.infoColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson.reviewStatus,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDue
                                ? context.warningColor
                                : context.infoColor,
                          ),
                        ),
                      ],
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

  Widget _buildContentIndicator(BuildContext context, IconData icon,
      String count, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}