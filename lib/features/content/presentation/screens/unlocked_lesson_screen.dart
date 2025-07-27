// lib/features/content/presentation/screens/unlocked_lesson_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/providers/content_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/features/files/presentation/screens/lesson_files_screen.dart';
import 'package:qvise/features/files/domain/usecases/create_file.dart';
import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

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
                  onCreate: () => _navigateToCreateFlashcard(context, ref, lesson),
                  onView: flashcardCount.asData?.value != null && flashcardCount.asData!.value > 0
                      ? () => _navigateToFlashcardPreview(context, ref, lesson.id)
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  context,
                  ref,
                  title: 'Files',
                  count: fileCount,
                  onCreate: () => _uploadFiles(context, ref, lesson.id),
                  onView: fileCount > 0
                      ? () => _navigateToLessonFiles(context, lesson.id)
                      : null,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _lockLesson(context, ref, lesson),
                    icon: const Icon(Icons.lock),
                    label: const Text('Lock & Start Learning'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text('Error: $error'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.refresh(lessonProvider(lessonId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int count,
    VoidCallback? onCreate,
    VoidCallback? onView,
  }) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    count.toString(),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: Text('Add $title'),
                  ),
                ),
                if (onView != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateFlashcard(BuildContext context, WidgetRef ref, dynamic lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: lesson.id,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
        ),
      ),
    ).then((_) {
      // Refresh relevant providers after creating flashcard
      ref.invalidate(flashcardCountProvider(lesson.id));
      ref.invalidate(lessonProvider(lesson.id));
    });
  }

  void _navigateToFlashcardPreview(BuildContext context, WidgetRef ref, String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(
          lessonId: lessonId,
          allowEditing: true,
        ),
      ),
    ).then((_) {
      // Refresh relevant providers after viewing flashcards
      ref.invalidate(flashcardCountProvider(lessonId));
      ref.invalidate(lessonProvider(lessonId));
    });
  }

  void _navigateToLessonFiles(BuildContext context, String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lessonId),
      ),
    );
  }

  void _uploadFiles(BuildContext context, WidgetRef ref, String lessonId) async {
    try {
      final filePickerService = ref.read(filePickerServiceProvider);
      final filePaths = await filePickerService.pickMultipleFiles(FileSource.files);
      
      if (filePaths.isNotEmpty) {
        final createFileUseCase = ref.read(createFileProvider);
        
        for (final filePath in filePaths) {
          try {
            final fileResult = await createFileUseCase(CreateFileParams(
              lessonId: lessonId,
              localPath: filePath,
            ));
            
            fileResult.fold(
              (failure) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to upload file: ${failure.userFriendlyMessage}')),
                  );
                }
              },
              (fileEntity) {
                // File uploaded successfully
              },
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload file: $e')),
              );
            }
          }
        }
        
        // Refresh file providers after upload
        ref.invalidate(lessonFilesProvider(lessonId));
        ref.invalidate(lessonProvider(lessonId));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Files uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }

  void _lockLesson(BuildContext context, WidgetRef ref, dynamic lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock Lesson'),
        content: const Text(
            'This will start the spaced repetition schedule for this lesson. You can still add content later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lock Lesson'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      try {
        final contentRepository = ref.read(contentRepositoryProvider);
        await contentRepository.lockLesson(lesson.id);
        
        // Refresh all relevant providers after locking
        ref.invalidate(unlockedLessonsProvider);
        ref.invalidate(lessonProvider(lesson.id));
        ref.invalidate(subjectsNotifierProvider);
        ref.invalidate(topicsNotifierProvider(lesson.subjectName));
        ref.invalidate(lessonsNotifierProvider(subjectName: lesson.subjectName, topicName: lesson.topicName));
        
        if (context.mounted) {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lesson locked and added to review schedule!')),
              );
            }
          });
        }
      } catch (e) {
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to lock lesson: $e')),
              );
            }
          });
        }
      }
    }
  }
}