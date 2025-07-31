// lib/features/content/presentation/screens/lesson_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
// Removed unused import
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/features/files/presentation/widgets/file_list_widget.dart';
import 'package:qvise/features/files/presentation/screens/lesson_files_screen.dart';
import 'package:qvise/features/files/domain/usecases/create_file.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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

        // Single screen that adapts based on lesson state
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
    final fileCount = filesAsync.maybeWhen(
      data: (files) => files.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.displayTitle),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Lesson'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteLesson(lesson);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            width: double.infinity,
            padding: AppSpacing.screenPaddingAll,
            decoration: BoxDecoration(
              color: context.surfaceVariantColor.withValues(alpha: 0.3), // FIXED: withOpacity to withValues
              border: Border(
                bottom: BorderSide(
                  color: context.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Flashcards',
                    flashcardCount.asData?.value?.toString() ?? '0',
                    Icons.quiz,
                    onTap: () => _tabController.animateTo(0),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Files',
                    fileCount.toString(),
                    Icons.folder,
                    onTap: () => _tabController.animateTo(1),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.quiz), text: 'Flashcards'),
              Tab(icon: Icon(Icons.folder), text: 'Files'),
            ],
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFlashcardsTab(lesson),
                _buildFilesTab(lesson, fileCount),
              ],
            ),
          ),
          
          // Lock Button
          Container(
            width: double.infinity,
            padding: AppSpacing.screenPaddingAll,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: context.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _lockLesson(lesson),
              icon: const Icon(Icons.lock),
              label: const Text('Lock & Start Learning'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String count,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: context.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: context.primaryColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              count,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.primaryColor,
              ),
            ),
            Text(
              title,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab(lesson) {
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
                'Flashcards',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _createFlashcard(lesson),
                icon: const Icon(Icons.add),
                label: const Text('Create'),
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
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: context.textTertiaryColor,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No Flashcards Yet',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          lesson.isLocked
                              ? 'No flashcards have been created for this lesson'
                              : 'Add flashcards to start learning!',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // ONLY SHOW CREATE BUTTON IN EDIT MODE
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
                        // ONLY SHOW EDIT BUTTON IN EDIT MODE
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
              // ONLY SHOW UPLOAD BUTTON IN EDIT MODE (when lesson is not locked)
              if (!lesson.isLocked)
                ElevatedButton.icon(
                  onPressed: () => _showFileUploadOptions(lesson), // FIXED: Call the upload options method
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

  Widget _buildStudyMode(lesson) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.displayTitle),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1), // FIXED: withOpacity to withValues
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.3), // FIXED: withOpacity to withValues
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.school,
                    size: 48,
                    color: context.primaryColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Study Mode',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This lesson is locked and ready for spaced repetition learning.',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Quick actions for study mode
            _buildQuickActions(lesson),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(lesson) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startFlashcardSession(lesson),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Flashcard Session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _viewFiles(lesson),
            icon: const Icon(Icons.folder_open),
            label: const Text('View Files'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.md),
            ),
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
            Text('The requested lesson could not be found.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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
            Text('Error: $error'),
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

  // FIXED: Properly refresh flashcard list after creation/editing
  void _createFlashcard(lesson) {
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
      // FIXED: Refresh both providers immediately when returning
      ref.invalidate(flashcardsByLessonProvider(lesson.id));
      ref.invalidate(flashcardCountProvider(lesson.id));
      _refreshLessonData();
    });
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
      // FIXED: Refresh both providers immediately when returning
      ref.invalidate(flashcardsByLessonProvider(lesson.id));
      ref.invalidate(flashcardCountProvider(lesson.id));
      _refreshLessonData();
    });
  }

  void _showFileUploadOptions(lesson) {
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
              subtitle: const Text('Choose from photo gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(lesson, FileSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Browse Files'),
              subtitle: const Text('Documents, PDFs (from any source)'),
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

  void _uploadFile(lesson, [FileSource source = FileSource.files]) async {
    try {
      final filePickerService = ref.read(filePickerServiceProvider);
      final filePaths = source == FileSource.files 
          ? await filePickerService.pickMultipleFiles(source)
          : [await filePickerService.pickFile(source)].where((path) => path != null).cast<String>().toList();
      
      if (filePaths.isNotEmpty) {
        final createFileUseCase = ref.read(createFileProvider);
        
        for (final filePath in filePaths) {
          try {
            final fileResult = await createFileUseCase(CreateFileParams(
              lessonId: lesson.id,
              localPath: filePath,
            ));
            
            fileResult.fold(
              (failure) {
                if (mounted) {
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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload file: $e')),
              );
            }
          }
        }
        
        _refreshLessonData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${filePaths.length} file(s) uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }

  void _refreshLessonData() {
    ref.invalidate(lessonFilesProvider(widget.lessonId));
    ref.invalidate(lessonProvider(widget.lessonId));
    ref.invalidate(flashcardCountProvider(widget.lessonId));
  }

  void _lockLesson(lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock Lesson'),
        content: const Text(
          'This will start the spaced repetition schedule for this lesson. You can still add content later.',
        ),
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

    if (confirmed == true) {
      try {
        await ref.read(lessonsNotifierProvider(
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
        ).notifier).lockLesson(lesson.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lesson locked successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to lock lesson: $e')),
          );
        }
      }
    }
  }

  void _deleteLesson(lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: const Text(
          'This will permanently delete the lesson and all its content (flashcards and files). This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(lessonsNotifierProvider(
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
        ).notifier).deleteLesson(lesson.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lesson deleted successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete lesson: $e')),
          );
        }
      }
    }
  }

  void _startFlashcardSession(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(lessonId: lesson.id),
      ),
    );
  }

  void _viewFiles(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lesson.id),
      ),
    );
  }
}