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
          tabs: const [
            Tab(text: 'Flashcards', icon: Icon(Icons.credit_card)),
            Tab(text: 'Files', icon: Icon(Icons.attachment)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showLessonInfo(lesson),
            icon: const Icon(Icons.info),
          ),
          IconButton(
            onPressed: () => _deleteLesson(lesson),
            icon: const Icon(Icons.delete),
            color: Colors.red,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Flashcards Tab
                _buildFlashcardsTab(lesson, flashcardCount.asData?.value ?? 0),
                // Files Tab
                _buildFilesTab(lesson, fileCount),
              ],
            ),
          ),
          // PROMINENT LOCK BUTTON (only enabled if lesson has content)
          Container(
            padding: AppSpacing.screenPaddingAll,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (flashcardCount.asData?.value ?? 0) > 0 || fileCount > 0
                    ? () => _lockLesson(lesson)
                    : null, // Disabled if lesson is empty
                icon: const Icon(Icons.lock),
                label: Text(
                  (flashcardCount.asData?.value ?? 0) > 0 || fileCount > 0
                      ? 'Lock & Start Learning'
                      : 'Add Content to Lock Lesson',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Study Mode: For locked lessons (spaced repetition)
  Widget _buildStudyMode(lesson) {
    final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));
    final filesAsync = ref.watch(lessonFilesProvider(lesson.id));

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
            // Lesson Stats Card
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
                          Icons.credit_card,
                        ),
                        _buildStatItem(
                          'Files',
                          '${filesAsync.maybeWhen(data: (files) => files.length, orElse: () => 0)}',
                          Icons.attachment,
                        ),
                        _buildStatItem(
                          'Proficiency',
                          '${(lesson.proficiency * 100).toInt()}%',
                          Icons.trending_up,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Action Buttons
            _buildActionButton(
              'Start Review Session',
              'Practice flashcards for this lesson',
              Icons.play_arrow,
              () => _startReviewSession(lesson),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Note: Your device\'s default file manager will open. This might be Google Drive if it\'s set as default.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
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
              // ONLY SHOW ADD BUTTON IN EDIT MODE
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
              allowEditing: !lesson.isLocked, // PASS EDITING PERMISSION BASED ON LOCK STATUS
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: context.primaryColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: context.primaryColor),
        const SizedBox(height: AppSpacing.xs),
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

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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

  void _showFileUploadOptions(BuildContext context, lesson) {
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

  void _viewFiles(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lesson.id),
      ),
    );
  }

  void _viewAllFlashcards(lesson) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FlashcardPreviewScreen(
        lessonId: lesson.id,
        allowEditing: !lesson.isLocked,  // ← FIX: Use lesson lock status
      ),
    ),
  ).then((_) => _refreshLessonData());
}

  // PROMINENT LOCK LESSON FUNCTIONALITY (moved from dropdown to main button)
  void _lockLesson(lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock Lesson'),
        content: const Text(
            'This will start the spaced repetition schedule for this lesson.\n\n'
            '⚠️ Warning: Once locked, you cannot add, edit, or remove any content from this lesson.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lock Lesson'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      try {
        final contentRepository = ref.read(contentRepositoryProvider);
        await contentRepository.lockLesson(lesson.id);
        
        // Refresh all relevant providers after locking
        ref.invalidate(unlockedLessonsProvider);
        ref.invalidate(lessonProvider(lesson.id));
        ref.invalidate(subjectsNotifierProvider);
        ref.invalidate(topicsNotifierProvider(lesson.subjectName));
        ref.invalidate(lessonsNotifierProvider(subjectName: lesson.subjectName, topicName: lesson.topicName));
        
        if (mounted) {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lesson locked and added to review schedule!')),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to lock lesson: $e')),
              );
            }
          });
        }
      }
    }
  }

  void _deleteLesson(lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.displayTitle}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      try {
        final contentRepository = ref.read(contentRepositoryProvider);
        await contentRepository.deleteLesson(lesson.id);
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete lesson: $e')),
              );
            }
          });
        }
      }
    }
  }

  void _startReviewSession(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(
          lessonId: lesson.id,
          allowEditing: false,
        ),
      ),
    ).then((_) => _refreshLessonData());
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
            _buildInfoRow('Subject', lesson.subjectName),
            _buildInfoRow('Topic', lesson.topicName),
            _buildInfoRow('Created', _formatDate(lesson.createdAt)),
            if (lesson.lastReviewedAt != null)
              _buildInfoRow('Last Reviewed', _formatDate(lesson.lastReviewedAt!)),
            _buildInfoRow('Review Stage', '${lesson.reviewStage}'),
            _buildInfoRow('Proficiency', '${(lesson.proficiency * 100).toStringAsFixed(1)}%'),
            _buildInfoRow('Status', lesson.isLocked ? 'Locked' : 'Unlocked'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatting without intl package
    return '${date.day}/${date.month}/${date.year}';
  }

  void _refreshLessonData() {
    ref.invalidate(lessonProvider(widget.lessonId));
    ref.invalidate(flashcardCountProvider(widget.lessonId));
    ref.invalidate(lessonFilesProvider(widget.lessonId));
    ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
  }
}