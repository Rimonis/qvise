// lib/features/content/presentation/screens/unlocked_lesson_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/features/files/presentation/screens/lesson_files_screen.dart';
import 'package:qvise/core/services/file_picker_service.dart';
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
        final filesAsync = ref.watch(lessonFilesProvider(lesson.id));
        final fileCount = filesAsync.maybeWhen(
          data: (files) => files.length,
          orElse: () => 0,
        );

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
                  ref,
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
                      ref.invalidate(lessonProvider(lesson.id));
                      ref.invalidate(unlockedLessonsProvider);
                    }
                  },
                  onPreview: () => context.push(
                    '${RouteNames.app}/preview/${lesson.id}',
                    extra: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSection(
                  context,
                  ref,
                  title: 'Files',
                  count: fileCount,
                  onCreate: () => _showAddFileOptions(context, ref, lesson.id),
                  onPreview: fileCount > 0 ? () => _navigateToFilesScreen(context, lesson.id) : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSection(context, ref, title: 'Notes', count: 0),
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
                  await ref
                      .read(lessonsNotifierProvider(
                              subjectName: lesson.subjectName, topicName: lesson.topicName)
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
    BuildContext context,
    WidgetRef ref, {
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
            Row(
              children: [
                Text(title, style: context.textTheme.headlineSmall),
                const Spacer(),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                    child: Text(
                      '$count',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              count == 0 
                ? 'No ${title.toLowerCase()} yet'
                : '$count ${count == 1 ? title.substring(0, title.length - 1).toLowerCase() : title.toLowerCase()}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCreate != null)
                  ElevatedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: Text('Add ${title.substring(0, title.length - 1)}'),
                  ),
                if (onCreate != null && onPreview != null)
                  const SizedBox(width: AppSpacing.sm),
                if (onPreview != null)
                  OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View All'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFileOptions(BuildContext context, WidgetRef ref, String lessonId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Add File',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.blue),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture a new photo'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final path = await ref
                      .read(filePickerServiceProvider)
                      .pickFile(FileSource.camera);
                  if (path != null) {
                    await ref.read(lessonFilesProvider(lessonId).notifier).addFile(path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select from your photos'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final path = await ref
                      .read(filePickerServiceProvider)
                      .pickFile(FileSource.gallery);
                  if (path != null) {
                    await ref.read(lessonFilesProvider(lessonId).notifier).addFile(path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_file, color: Colors.orange),
                ),
                title: const Text('Browse Files'),
                subtitle: const Text('PDF, documents, and more'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final path = await ref
                      .read(filePickerServiceProvider)
                      .pickFile(FileSource.files);
                  if (path != null) {
                    await ref.read(lessonFilesProvider(lessonId).notifier).addFile(path);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _navigateToFilesScreen(BuildContext context, String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lessonId),
      ),
    );
  }
}