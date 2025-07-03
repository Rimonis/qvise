import 'package:flutter/material.dart';
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
    final proficiencyColor =
        Color(int.parse(subject.proficiencyColor.replaceAll('#', '0xFF')));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                      color: proficiencyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school,
                      color: proficiencyColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: context.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.topicCount} topics • ${subject.lessonCount} lessons',
                          style: context.textTheme.bodyMedium,
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
                      icon: Icon(Icons.more_vert, color: context.iconColor),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Proficiency indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Proficiency',
                        style: context.textTheme.bodySmall,
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
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: subject.proficiency,
                      minHeight: 8,
                      backgroundColor: context.dividerColor,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(proficiencyColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject.proficiencyLabel,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: proficiencyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Last studied
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last studied: ${_formatLastStudied(subject.lastStudied)}',
                    style: context.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.textTertiaryColor,
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