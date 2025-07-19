// lib/features/content/presentation/widgets/unlocked_lesson_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/screens/lesson_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class UnlockedLessonCard extends ConsumerWidget {
  final Lesson lesson;
  final VoidCallback? onTap;
  final VoidCallback? onLessonUpdated;

  const UnlockedLessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.onLessonUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));
    final filesAsync = ref.watch(lessonFilesProvider(lesson.id));
    final fileCount = filesAsync.maybeWhen(
      data: (files) => files.length,
      orElse: () => 0,
    );

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap ?? () => _navigateToLesson(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${lesson.subjectName} › ${lesson.topicName}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Editing',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Content Stats
              Row(
                children: [
                  _buildStatChip(
                    context,
                    icon: Icons.style,
                    label: 'Flashcards',
                    count: flashcardCount.asData?.value ?? 0,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatChip(
                    context,
                    icon: Icons.attach_file,
                    label: 'Files',
                    count: fileCount,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatChip(
                    context,
                    icon: Icons.note,
                    label: 'Notes',
                    count: 0, // Notes not implemented yet
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap ?? () => _navigateToLesson(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Add Content'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: context.textSecondaryColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            count.toString(),
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLesson(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(lessonId: lesson.id), // Using unified screen
      ),
    );
    
    // If the lesson was modified, trigger the callback to refresh the parent
    if (result == true || onLessonUpdated != null) {
      onLessonUpdated?.call();
    }
  }
}