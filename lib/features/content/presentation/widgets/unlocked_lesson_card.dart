import 'package:flutter/material.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/lesson.dart';

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
    final hasContent = lesson.totalContentCount > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasContent
            ? BorderSide(color: context.successColor.withOpacity(0.5), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tags and status
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
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: context.primaryColor),
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
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: context.secondaryColor),
                    ),
                  ),
                  const Spacer(),
                  // Status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasContent
                          ? context.successColor.withOpacity(0.1)
                          : context.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasContent
                            ? context.successColor.withOpacity(0.3)
                            : context.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasContent ? Icons.check_circle : Icons.edit,
                          size: 12,
                          color: hasContent
                              ? context.successColor
                              : context.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasContent ? 'Ready' : 'Empty',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: hasContent
                                ? context.successColor
                                : context.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  color: context.errorColor, size: 20),
                              const SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: context.errorColor)),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert,
                          size: 20, color: context.iconColor),
                    ),
                  ],
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
              const SizedBox(height: 8),

              // Created date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created ${lesson.dayCreated}',
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content summary
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

                  if (lesson.totalContentCount == 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'No content yet',
                        style: context.textTheme.bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Edit indicator
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: context.primaryColor,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            count,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}