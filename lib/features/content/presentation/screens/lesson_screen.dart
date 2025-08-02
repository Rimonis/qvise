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

  Widget _buildEditMode(lesson) {
    final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));
    final filesAsync = ref.watch(lessonFilesProvider(lesson.id));
    final notesAsync = ref.watch(lessonNotesProvider(lesson.id));
    final fileCount = filesAsync.maybeWhen(
      data: (files) => files.length,
      orElse: () => 0,
    );
    final noteCount = notesAsync.maybeWhen(
      data: (notes) => notes.length,
      orElse: () => 0,
    );

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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.style),
              child: Column(
                children: [
                  const Text('Flashcards'),
                  Text(
                    '${flashcardCount.asData?.value ?? 0}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.attach_file),
              child: Column(
                children: [
                  const Text('Files'),
                  Text(
                    '$fileCount',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.note),
              child: Column(
                children: [
                  const Text('Notes'),
                  Text(
                    '$noteCount',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
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
                          '${filesAsync.asData?.value?.length ?? 0}',
                          Icons.attach_file,
                        ),
                        _buildStatItem(
                          'Notes',
                          '${notesAsync.asData?.value?.length ?? 0}',
                          Icons.note,
                        ),
                        _buildStatItem(
                          'Proficiency',
                          '${(lesson.proficiency * 100).round()}%',
                          Icons.trending_up,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Study Options',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            _buildActionButton(
              'Review Flashcards',
              'Practice with spaced repetition',
              Icons.quiz,
              () => _reviewFlashcards(lesson),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            _buildActionButton(
              'View Study Materials',
              'Access files and notes for reference',
              Icons.library_books,
              () => _viewStudyMaterials(lesson),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            const Text(
              'Note: Files will be opened in your device\'s default app.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            _buildActionButton(
              'View All Flashcards',
              'Browse all flashcards in this lesson',
              Icons.visibility,
              () => _viewAllFlashcards(lesson),
            ),
            const SizedBox(height: AppSpacing.md),
            
            if (filesAsync.hasValue && filesAsync.value!.isNotEmpty)
              _buildActionButton(
                'View Files',
                '${filesAsync.value!.length} files attached',
                Icons.attachment,
                () => _viewFiles(lesson),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab(lesson, int flashcardCount) {
    final flashcardsAsync = ref.watch(flashcardsByLessonProvider(lesson.id));
    
    return Padding(
      padding: AppSpacing.screenPaddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Flashcards ($flashcardCount)',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!lesson.isLocked)
                ElevatedButton.icon(
                  onPressed: () => _createFlashcard(lesson),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          Expanded(
            child: flashcardsAsync.when(
              data: (flashcards) {
                if (flashcards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card, size: 64, color: Colors.grey),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No Flashcards Yet',
                          style: context.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          lesson.isLocked 
                              ? 'No flashcards have been created for this lesson'
                              : 'Add flashcards to start learning!',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (!lesson.isLocked)
                          ElevatedButton.icon(
                            onPressed: () => _createFlashcard(lesson),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Flashcard'),
                          ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: flashcards.length,
                  itemBuilder: (context, index) {
                    final flashcard = flashcards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        title: Text(flashcard.frontContent),
                        subtitle: Text(
                          flashcard.backContent,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: !lesson.isLocked 
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editFlashcard(lesson, flashcard),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab(lesson, int fileCount) {
    return Padding(
      padding: AppSpacing.screenPaddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Files ($fileCount)',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!lesson.isLocked)
                ElevatedButton.icon(
                  onPressed: () => _uploadFile(lesson),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          Expanded(
            child: FileListWidget(
              lessonId: lesson.id,
              allowEditing: !lesson.isLocked,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(lesson, int noteCount) {
    return NoteListWidget(lessonId: lesson.id);
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: AppSpacing.paddingAllMd,
            child: Row(
              children: [
                Icon(icon, size: 32, color: context.primaryColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.textSecondaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: context.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.primaryColor,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: AppSpacing.md),
            Text('This lesson could not be found.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading...')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading lesson: $error'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => ref.refresh(lessonProvider(widget.lessonId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _createFlashcard(lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: lesson.id,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
        ),
      ),
    );
  }

  void _editFlashcard(lesson, flashcard) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: lesson.id,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
          flashcardToEdit: flashcard,
        ),
      ),
    );
  }

  void _reviewFlashcards(lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(lessonId: lesson.id),
      ),
    );
  }

  void _viewAllFlashcards(lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(lessonId: lesson.id),
      ),
    );
  }

  void _viewFiles(lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lesson.id),
      ),
    );
  }

  void _viewStudyMaterials(lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lesson.id),
      ),
    );
  }

  void _uploadFile(lesson) async {
    try {
      final filePickerService = ref.read(filePickerServiceProvider);
      final filePaths = await filePickerService.pickMultipleFiles(FileSource.files);
      
      if (filePaths.isNotEmpty) {
        final createFileUseCase = ref.read(createFileProvider);
        
        for (final filePath in filePaths) {
          await createFileUseCase(CreateFileParams(
            lessonId: lesson.id,
            localPath: filePath,
          ));
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Files uploaded successfully!')),
          );
        }
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
      await lockUseCase(lesson.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson locked! You can now start studying.')),
        );
      }
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
}