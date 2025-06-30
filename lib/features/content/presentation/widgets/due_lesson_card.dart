import 'package:flutter/material.dart';
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
    final proficiencyColor = Color(int.parse(lesson.proficiencyColor.replaceAll('#', '0xFF')));
    
    return Card(
      elevation: isDue ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDue
            ? BorderSide(color: Colors.orange.withOpacity(0.6), width: 2)
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      lesson.subjectName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Topic tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      lesson.topicName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Day created
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lesson.dayCreated,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Lesson title
              Text(
                lesson.displayTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${(lesson.reviewStageProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
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
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(proficiencyColor),
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
                      Icons.style,
                      lesson.flashcardCount.toString(),
                      'Flashcards',
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (lesson.fileCount > 0) ...[
                    _buildContentIndicator(
                      Icons.attachment,
                      lesson.fileCount.toString(),
                      'Files',
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (lesson.noteCount > 0) ...[
                    _buildContentIndicator(
                      Icons.note,
                      lesson.noteCount.toString(),
                      'Notes',
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  
                  // Review status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDue ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDue ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDue ? Icons.alarm : Icons.schedule,
                          size: 14,
                          color: isDue ? Colors.orange[700] : Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson.reviewStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDue ? Colors.orange[700] : Colors.blue[700],
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
  
  Widget _buildContentIndicator(IconData icon, String count, String label, Color color) {
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}