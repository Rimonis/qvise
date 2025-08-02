// lib/features/content/presentation/screens/lesson_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/providers/content_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/features/files/presentation/widgets/file_list_widget.dart';
import 'package:qvise/features/files/presentation/screens/lesson_files_screen.dart';
import 'package:qvise/features/files/domain/usecases/create_file.dart';
import 'package:qvise/features/notes/presentation/providers/note_providers.dart';
import 'package:qvise/features/notes/presentation/widgets/note_list_widget.dart';
import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.lessonId,
  void _editFlashcard(lesson, flashcard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: lesson.id,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
          flashcardToEdit: flashcard,
        ),
      ),
    ).then((_) {
      // Refresh flashcard data when returning from edit screen
      ref.invalidate(flashcardCountProvider(lesson.id));
      ref.invalidate(flashcardsByLessonProvider(lesson.id));
    });
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return _buildNotFoundScreen();
        }

        if (lesson.isLocked) {
          return _buildStudyMode(lesson);
        } else {
          return _buildEditMode(lesson);
        }
      },
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error.toString()),
    );
  }

  // Edit Mode: For unlocked lessons (content creation)
  Widget _buildEditMode(lesson) {
    final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));
    final filesAsync = ref.watch(lessonFilesProvider(lesson.id));
    final notesAsync = ref.watch(lessonNotesProvider(lesson.id));
    
    final fileCount = filesAsync.asData?.value.length ?? 0;
    final noteCount = notesAsync.asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.displayTitle, style: const TextStyle(fontSize: 18)),
            Text(
              '${lesson.subjectName} › ${lesson.topicName}',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showLessonInfo(lesson);
                  break;
                case 'delete':
                  _deleteLesson(lesson);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: AppSpacing.sm),
                    Text('Lesson Info'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: AppSpacing.sm),
                    Text('Delete Lesson', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Flashcards (${flashcardCount.asData?.value ?? 0})'),
            Tab(text: 'Files ($fileCount)'),
            Tab(text: 'Notes ($noteCount)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlashcardsTab(lesson, flashcardCount.asData?.value ?? 0),
          _buildFilesTab(lesson, fileCount),
          _buildNotesTab(lesson, noteCount),
        ],
      ),
      bottomNavigationBar: Container(
        padding: AppSpacing.paddingAllMd,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (flashcardCount.asData?.value ?? 0) > 0 || fileCount > 0 || noteCount > 0
                  ? () => _lockLesson(lesson)
                  : null,
              icon: const Icon(Icons.lock),
              label: Text(
                (flashcardCount.asData?.value ?? 0) > 0 || fileCount > 0 || noteCount > 0
                    ? 'Lock & Start Learning'
                    : 'Add Content to Lock Lesson',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyMode(lesson) {
    final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));
    final filesAsync = ref.watch(lessonFilesProvider(lesson.id));
    final notesAsync = ref.watch(lessonNotesProvider(lesson.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.displayTitle, style: const TextStyle(fontSize: 18)),
            Text(
              '${lesson.subjectName} › ${lesson.topicName}',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showLessonInfo(lesson),
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Progress',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Flashcards',
                          '${flashcardCount.asData?.value ?? 0}',
                          Icons.style,
                        ),
                        _buildStatItem(
                          'Files',
                          '${filesAsync.asData?.value.length ?? 0}',
                          Icons.attach_file,
                        ),
                        _buildStatItem(
                          'Notes',
                          '${notesAsync.asData?.value.length ?? 0}',
                          Icons.note,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LinearProgressIndicator(
                      value: lesson.proficiency,
                      backgroundColor: context.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Proficiency: ${(lesson.proficiency * 100).round()}%',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.quiz),
                    title: const Text('Review Flashcards'),
                    subtitle: Text('${flashcardCount.asData?.value ?? 0} cards available'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: flashcardCount.asData?.value != null && flashcardCount.asData!.value > 0
                        ? () => _navigateToFlashcardReview(lesson)
                        : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('View Files'),
                    subtitle: Text('${filesAsync.asData?.value.length ?? 0} files'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _navigateToFiles(lesson),
                  ),
                  ListTile(
                    leading: const Icon(Icons.note),
                    title: const Text('View Notes'),
                    subtitle: Text('${notesAsync.asData?.value.length ?? 0} notes'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showNotesDialog(lesson),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab(lesson, int count) {
    if (!lesson.isLocked) {
      // Edit mode - show add button and allow editing
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Flashcards ($count)',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigateToFlashcardCreation(lesson),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: count == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.style, size: 64, color: context.colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No flashcards yet',
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Flashcards help you memorize key concepts',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildFlashcardsList(lesson),
          ),
        ],
      );
    } else {
      // Study mode - just show flashcards without edit options
      if (count == 0) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.style, size: 64, color: context.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No flashcards in this lesson',
                style: context.textTheme.titleMedium,
              ),
            ],
          ),
        );
      }
      return _buildFlashcardsList(lesson);
    }
  }

  Widget _buildFlashcardsList(lesson) {
    final flashcardsAsync = ref.watch(flashcardsByLessonProvider(lesson.id));
    return flashcardsAsync.when(
      data: (flashcards) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: flashcards.length,
        itemBuilder: (context, index) {
          final flashcard = flashcards[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              title: Text(flashcard.frontContent, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(flashcard.backContent, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(label: Text(_getDifficultyLabel(flashcard.difficulty))),
                  if (!lesson.isLocked) ...[
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editFlashcard(lesson, flashcard),
                    ),
                  ],
                ],
              ),
              onTap: () => _showFlashcardDetail(flashcard),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildFilesTab(lesson, int count) {
    if (!lesson.isLocked) {
      // Edit mode - show upload button
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Files ($count)',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _attachFiles(lesson),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload'),
                ),
              ],
            ),
          ),
          Expanded(
            child: count == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_file, size: 64, color: context.colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No files attached',
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Add PDFs, images, or documents',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : FileListWidget(
                    lessonId: lesson.id,
                    allowEditing: true,
                  ),
          ),
        ],
      );
    } else {
      // Study mode - no upload button
      if (count == 0) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_file, size: 64, color: context.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No files in this lesson',
                style: context.textTheme.titleMedium,
              ),
            ],
          ),
        );
      }
      return FileListWidget(
        lessonId: lesson.id,
        allowEditing: false,
      );
    }
  }

  Widget _buildNotesTab(lesson, int count) {
    return NoteListWidget(
      lessonId: lesson.id,
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: context.colorScheme.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: context.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading...')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Lesson not found',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPaddingAll,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: context.colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'An error occurred',
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.invalidate(lessonProvider(widget.lessonId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFlashcardCreation(lesson) {
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
      // Refresh flashcard data when returning from creation screen
      ref.invalidate(flashcardCountProvider(lesson.id));
      ref.invalidate(flashcardsByLessonProvider(lesson.id));
    });
  }

  void _navigateToFlashcardReview(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(
          lessonId: lesson.id,
        ),
      ),
    );
  }

  void _editFlashcard(lesson, flashcard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: lesson.id,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
          flashcardToEdit: flashcard,
        ),
      ),
    ).then((_) {
      // Refresh flashcard data when returning from edit screen
      ref.invalidate(flashcardCountProvider(lesson.id));
      ref.invalidate(flashcardsByLessonProvider(lesson.id));
    });
  }

  void _navigateToFiles(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lesson.id),
      ),
    );
  }

  void _showFlashcardDetail(flashcard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question:', style: context.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(flashcard.frontContent),
            const SizedBox(height: AppSpacing.md),
            Text('Answer:', style: context.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(flashcard.backContent),
            const SizedBox(height: AppSpacing.md),
            Chip(label: Text('Difficulty: ${_getDifficultyLabel(flashcard.difficulty)}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: AppSpacing.paddingAllMd,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notes',
                    style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                // FIX: Removed scrollController parameter as it doesn't exist in NoteListWidget
                child: NoteListWidget(
                  lessonId: lesson.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attachFiles(lesson) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                'Upload File',
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
              onTap: () {
                Navigator.pop(context);
                _uploadFile(lesson, FileSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(lesson, FileSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Browse Files'),
              subtitle: const Text('Documents, PDFs, and more'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(lesson, FileSource.files);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(lesson, FileSource source) async {
    try {
      final filePickerService = ref.read(filePickerServiceProvider);
      final pickedFiles = await filePickerService.pickMultipleFiles(source);

      if (pickedFiles.isEmpty) return;

      final createFileUseCase = ref.read(createFileProvider);

      for (final filePath in pickedFiles) {
        await createFileUseCase(CreateFileParams(
          lessonId: lesson.id,
          localPath: filePath,
        ));
      }

      ref.invalidate(lessonFilesProvider(lesson.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pickedFiles.length} file(s) uploaded successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload files: ${e.toString()}'),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    }
  }

  void _lockLesson(lesson) async {
    try {
      final lockUseCase = ref.read(lockLessonUseCaseProvider);
      final result = await lockUseCase(lesson.id);
      
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to lock lesson: ${failure.userFriendlyMessage}'),
                backgroundColor: context.colorScheme.error,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lesson locked! You can now start studying.')),
            );
            // Refresh the lesson to show the updated state
            ref.invalidate(lessonProvider(widget.lessonId));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to lock lesson: ${e.toString()}'),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    }
  }

  void _showLessonInfo(lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lesson.displayTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${lesson.subjectName}'),
            Text('Topic: ${lesson.topicName}'),
            Text('Status: ${lesson.isLocked ? "Locked" : "Unlocked"}'),
            if (lesson.isLocked) ...[
              Text('Proficiency: ${(lesson.proficiency * 100).round()}%'),
              Text('Review Stage: ${lesson.reviewStage}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getDifficultyLabel(double difficulty) {
    if (difficulty < 0.33) return 'Easy';
    if (difficulty < 0.67) return 'Medium';
    return 'Hard';
  }
}