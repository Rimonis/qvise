// lib/features/content/presentation/screens/lesson_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
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
    
    // Fixed: Listen to create file state changes properly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<void>>(createFileNotifierProvider, (previous, next) {
        next.whenOrNull(
          error: (error, stack) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload file: $error')),
              );
            }
          },
          data: (_) {
            if (previous?.isLoading == true) {
              _refreshLessonData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File uploaded successfully')),
                );
              }
            }
          },
        );
      });
    });
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
  Widget _buildEditMode(dynamic lesson) {
    final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));
    final filesAsync = ref.watch(lessonFilesProvider(lesson.id));
    final fileCount = filesAsync.maybeWhen(
      data: (files) => files.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'lock':
                  _lockLesson(lesson);
                  break;
                case 'delete':
                  _showDeleteConfirmation(lesson);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'lock',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Lock for Study'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Lesson', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.quiz),
              text: 'Flashcards ($flashcardCount)',
            ),
            Tab(
              icon: const Icon(Icons.attach_file),
              text: 'Files ($fileCount)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlashcardsTab(lesson),
          _buildFilesTab(lesson),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(lesson),
    );
  }

  Widget _buildFlashcardsTab(dynamic lesson) {
    // Fixed: Use correct provider name - flashcardsByLessonProvider instead of lessonFlashcardsProvider
    final flashcardsAsync = ref.watch(flashcardsByLessonProvider(lesson.id));
    
    return flashcardsAsync.when(
      data: (flashcards) {
        if (flashcards.isEmpty) {
          return _buildEmptyFlashcardsState(lesson);
        }
        
        return FlashcardPreviewScreen(
          lessonId: lesson.id,
          allowEditing: true,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading flashcards: $error'),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              // Fixed: Use correct provider name
              onPressed: () => ref.refresh(flashcardsByLessonProvider(lesson.id)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesTab(dynamic lesson) {
    return FileListWidget(
      lessonId: lesson.id,
      allowEditing: true,
    );
  }

  Widget _buildEmptyFlashcardsState(dynamic lesson) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Flashcards Yet',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create flashcards to start studying this lesson',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _createFlashcard(lesson),
              icon: const Icon(Icons.add),
              label: const Text('Create Flashcard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(dynamic lesson) {
    return FloatingActionButton(
      onPressed: () => _showAddMenu(lesson),
      child: const Icon(Icons.add),
    );
  }

  void _showAddMenu(dynamic lesson) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Add Content',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Create Flashcard'),
              subtitle: const Text('Add a new flashcard to this lesson'),
              onTap: () {
                Navigator.pop(context);
                _createFlashcard(lesson);
              },
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

  void _uploadFile(dynamic lesson, [FileSource source = FileSource.files]) async {
    try {
      final filePickerService = ref.read(filePickerServiceProvider);
      final filePaths = source == FileSource.files 
          ? await filePickerService.pickMultipleFiles(source)
          : [await filePickerService.pickFile(source)].where((path) => path != null).cast<String>().toList();
      
      if (filePaths.isNotEmpty) {
        final createFileNotifier = ref.read(createFileNotifierProvider.notifier);
        
        for (final filePath in filePaths) {
          await createFileNotifier.createFile(CreateFileParams(
            lessonId: lesson.id,
            localPath: filePath,
          ));
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${filePaths.length} file(s) upload started')),
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

  void _createFlashcard(dynamic lesson) {
    // Fixed: Pass required subjectName and topicName parameters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: lesson.id,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
        ),
      ),
    );
  }

  void _lockLesson(dynamic lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock Lesson for Study'),
        content: const Text(
          'This will lock the lesson and make it available for studying. '
          'You won\'t be able to edit flashcards or add files after locking.',
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
      // Fixed: Pass required subjectName and topicName parameters to lessonsNotifierProvider
      final lessonNotifier = ref.read(lessonsNotifierProvider(
        subjectName: lesson.subjectName,
        topicName: lesson.topicName,
      ).notifier);
      await lessonNotifier.lockLesson(lesson.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lesson.displayTitle} is now ready for study!'),
            action: SnackBarAction(
              label: 'Study Now',
              onPressed: () {
                // Navigate to study mode
                _refreshLessonData();
              },
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(dynamic lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppSpacing.paddingAllSm,
              decoration: BoxDecoration(
                color: context.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: context.infoColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title: ${lesson.displayTitle}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Fixed: Remove null-aware operator since lesson can't be null here
                  Text(
                    'Created: ${_formatDate(lesson.createdAt)}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'Proficiency: ${(lesson.proficiency * 100).toInt()}%',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.paddingAllSm,
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: context.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'This will also delete all flashcards and files in this lesson.\n\nThis action cannot be undone.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
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
      // Fixed: Pass required subjectName and topicName parameters to lessonsNotifierProvider
      final lessonNotifier = ref.read(lessonsNotifierProvider(
        subjectName: lesson.subjectName,
        topicName: lesson.topicName,
      ).notifier);
      await lessonNotifier.deleteLesson(lesson.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson deleted successfully')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Study Mode: For locked lessons (study session)
  Widget _buildStudyMode(dynamic lesson) {
    final flashcardCount = ref.watch(flashcardCountProvider(lesson.id));
    final filesAsync = ref.watch(lessonFilesProvider(lesson.id));
    final fileCount = filesAsync.maybeWhen(
      data: (files) => files.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _viewFiles(lesson),
            icon: const Icon(Icons.folder_open),
            tooltip: 'View Files',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Lesson stats
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    lesson.displayTitle,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Flashcards', flashcardCount.toString()),
                      _buildStatCard('Files', fileCount.toString()),
                      _buildStatCard('Proficiency', '${(lesson.proficiency * 100).toInt()}%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Study session info
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.school,
                    size: 64,
                    color: context.primaryColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Ready to Study!',
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This lesson is locked and ready for your study session',
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

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
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

  Widget _buildQuickActions(dynamic lesson) {
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

  void _startFlashcardSession(dynamic lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(
          lessonId: lesson.id,
          allowEditing: false,
        ),
      ),
    );
  }

  void _viewFiles(dynamic lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lesson.id),
      ),
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
            Text('Error: $error'),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(lessonProvider(widget.lessonId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshLessonData() {
    ref.invalidate(lessonProvider(widget.lessonId));
    ref.invalidate(lessonFilesProvider(widget.lessonId));
    ref.invalidate(flashcardCountProvider(widget.lessonId));
    // Fixed: Use correct provider name
    ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
  }
}