// lib/features/content/presentation/screens/unlocked_lesson_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import 'package:qvise/core/routes/route_names.dart';

class UnlockedLessonScreen extends ConsumerWidget {
  final String lessonId;

  const UnlockedLessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonProvider(lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return const Scaffold(
            body: Center(child: Text('Lesson not found.')),
          );
        }
        final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));

        return Scaffold(
          appBar: AppBar(
            title: Text(lesson.displayTitle),
          ),
          body: Padding(
            padding: AppSpacing.screenPaddingAll,
            child: Column(
              children: [
                _buildSection(
                  context,
                  title: 'Flashcards',
                  count: flashcardCount.asData?.value ?? 0,
                  onCreate: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlashcardCreationScreen(
                          lessonId: lesson.id,
                          subjectName: lesson.subjectName,
                          topicName: lesson.topicName,
                        ),
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(flashcardCountProvider(lesson.id));
                      ref.invalidate(lessonProvider(lesson.id)); // Refresh lesson data
                      ref.invalidate(unlockedLessonsProvider);
                    }
                  },
                  onPreview: () => context.push(
                    '${RouteNames.app}/preview/${lesson.id}',
                    extra: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSection(context, title: 'Files', count: 0),
                const SizedBox(height: AppSpacing.md),
                _buildSection(context, title: 'Notes', count: 0),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: AppSpacing.paddingAllMd,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Lock Lesson?'),
                    content: const Text(
                        'This will start the spaced repetition schedule for this lesson.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Lock')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // Call the notifier method which handles invalidation
                  await ref
                      .read(lessonsNotifierProvider(
                              lesson.subjectName, lesson.topicName)
                          .notifier)
                      .lockLesson(lesson.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.lock),
              label: const Text('Lock Lesson'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required int count,
    VoidCallback? onCreate,
    VoidCallback? onPreview,
  }) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('$count items'),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCreate != null)
                  ElevatedButton(
                    onPressed: onCreate,
                    child: const Text('Create'),
                  ),
                const SizedBox(width: AppSpacing.sm),
                if (onPreview != null)
                  OutlinedButton(
                    onPressed: onPreview,
                    child: const Text('Preview'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}