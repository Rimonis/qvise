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
                      // Refresh flashcard count and lesson data
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
                    await ref.read(unlockedLessonsProvider.notifier).lockLesson(lesson.id);
                    // Refresh all relevant providers after locking
                    ref.invalidate(unlockedLessonsProvider);
                    ref.invalidate(lessonProvider(lesson.id));
                    ref.invalidate(subjectsNotifierProvider);
                    ref.invalidate(topicsNotifierProvider(subjectName: lesson.subjectName));
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
              },
              icon: const Icon(Icons.lock),
              label: const Text('Lock & Start Learning'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
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
                Icon(
                  _getIconForSection(title),
                  color: context.primaryColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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
                    style: TextStyle(
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
                if (onCreate != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add),
                      label: Text('Add ${title.substring(0, title.length - 1)}'),
                    ),
                  ),
                  if (onPreview != null) const SizedBox(width: AppSpacing.sm),
                ],
                if (onPreview != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPreview,
                      icon: const Icon(Icons.visibility),
                      label: const Text('View All'),
                    ),
                  ),
                if (onCreate == null && onPreview == null)
                  const Expanded(
                    child: Text(
                      'Coming soon',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSection(String title) {
    switch (title.toLowerCase()) {
      case 'flashcards':
        return Icons.style;
      case 'files':
        return Icons.attach_file;
      case 'notes':
        return Icons.note;
      default:
        return Icons.folder;
    }
  }

  void _showAddFileOptions(BuildContext context, WidgetRef ref, String lessonId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
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
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Add File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture with camera'),
              onTap: () async {
                Navigator.pop(context);
                await _addFile(context, ref, lessonId, FileSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _addFile(context, ref, lessonId, FileSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Browse Files'),
              subtitle: const Text('Documents, PDFs, etc.'),
              onTap: () async {
                Navigator.pop(context);
                await _addFile(context, ref, lessonId, FileSource.files);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _addFile(BuildContext context, WidgetRef ref, String lessonId, FileSource source) async {
    try {
      final filePicker = ref.read(filePickerServiceProvider);
      final filePath = await filePicker.pickFile(source);
      
      if (filePath != null) {
        await ref.read(lessonFilesProvider(lessonId).notifier).addFile(filePath);
        
        // Refresh file count and lesson data
        ref.invalidate(lessonFilesProvider(lessonId));
        ref.invalidate(lessonProvider(lessonId));
        ref.invalidate(unlockedLessonsProvider);
        
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File added successfully!')),
              );
            }
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add file: $e')),
            );
          }
        });
      }
    }
  }

  void _navigateToFilesScreen(BuildContext context, String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lessonId),
      ),
    ).then((_) {
      // Refresh file count when returning from files screen
      // This ensures any deletions or changes are reflected
      ref.invalidate(lessonFilesProvider(lessonId));
      ref.invalidate(lessonProvider(lessonId));
      ref.invalidate(unlockedLessonsProvider);
    });
  }
}