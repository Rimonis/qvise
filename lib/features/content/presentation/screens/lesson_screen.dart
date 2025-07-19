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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
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
                Icon(Icons.edit, size: 14, color: Colors.orange[700]),
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
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          children: [
            _buildEditSection(
              context,
              title: 'Flashcards',
              count: flashcardCount.asData?.value ?? 0,
              icon: Icons.style,
              onCreate: () => _createFlashcard(lesson),
              onPreview: (flashcardCount.asData?.value ?? 0) > 0 
                  ? () => _previewFlashcards(lesson) 
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildEditSection(
              context,
              title: 'Files',
              count: fileCount,
              icon: Icons.attach_file,
              onCreate: () => _addFile(lesson.id),
              onPreview: fileCount > 0 ? () => _viewFiles(lesson.id) : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildEditSection(
              context,
              title: 'Notes',
              count: 0,
              icon: Icons.note,
              isComingSoon: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: AppSpacing.paddingAllMd,
        child: ElevatedButton.icon(
          onPressed: () => _lockLesson(lesson),
          icon: const Icon(Icons.lock),
          label: const Text('Lock & Start Learning'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: context.primaryColor,
          ),
        ),
      ),
    );
  }

  // Study Mode: For locked lessons (review/study)
  Widget _buildStudyMode(lesson) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLessonInfo(lesson),
          ),
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 14, color: Colors.green[700]),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Locked',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.style),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Study'),
                  if (flashcardCount.hasValue)
                    Text(
                      '${flashcardCount.asData!.value}',
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Reference'),
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyTab(lesson),
          _buildReferenceTab(lesson),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: AppSpacing.paddingAllMd,
        child: ElevatedButton.icon(
          onPressed: () => _startReviewSession(lesson),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Review Session'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildEditSection(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    VoidCallback? onCreate,
    VoidCallback? onPreview,
    bool isComingSoon = false,
  }) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.primaryColor),
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
            if (isComingSoon)
              const Text(
                'Coming soon',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
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
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyTab(lesson) {
    final flashcardsAsync = ref.watch(flashcardsByLessonProvider(widget.lessonId));

    return flashcardsAsync.when(
      data: (flashcards) {
        if (flashcards.isEmpty) {
          return _buildEmptyStudyState();
        }

        return Column(
          children: [
            // Study progress
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Progress',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProgressStat('Total', '${flashcards.length}', Icons.style),
                      _buildProgressStat(
                        'Reviewed',
                        '${flashcards.where((f) => f.reviewCount > 0).length}',
                        Icons.check_circle,
                      ),
                      _buildProgressStat(
                        'Mastered',
                        '${flashcards.where((f) => f.masteryLevel > 0.8).length}',
                        Icons.star,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Quick study actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startReviewSession(lesson),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Study All'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _previewFlashcards(lesson),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Browse'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('Failed to load flashcards'),
    );
  }

  Widget _buildReferenceTab(lesson) {
    return FileListWidget(lessonId: widget.lessonId);
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700]),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyStudyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Content to Study',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This lesson was locked without any flashcards',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: AppSpacing.md),
            Text('Lesson not found', style: TextStyle(fontSize: 18)),
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

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: AppSpacing.md),
          Text(message),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _createFlashcard(lesson) async {
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
      _refreshLessonData();
    }
  }

  void _previewFlashcards(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(
          lessonId: lesson.id,
          allowEditing: !lesson.isLocked,
        ),
      ),
    ).then((_) => _refreshLessonData());
  }

  void _addFile(String lessonId) {
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
                await _pickAndAddFile(FileSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndAddFile(FileSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Browse Files'),
              subtitle: const Text('Documents, PDFs, etc.'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndAddFile(FileSource.files);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAddFile(FileSource source) async {
    try {
      final filePicker = ref.read(filePickerServiceProvider);
      final filePath = await filePicker.pickFile(source);
      
      if (filePath != null) {
        await ref.read(lessonFilesProvider(widget.lessonId).notifier).addFile(filePath);
        _refreshLessonData();
        
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File added successfully!')),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add file: $e')),
            );
          }
        });
      }
    }
  }

  void _viewFiles(String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonFilesScreen(lessonId: lessonId),
      ),
    ).then((_) => _refreshLessonData());
  }

  Future<void> _lockLesson(lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock Lesson?'),
        content: const Text(
          'This will start the spaced repetition schedule for this lesson. '
          'You can still add content later, but the lesson will be in study mode.',
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
        await ref.read(unlockedLessonsProvider.notifier).lockLesson(lesson.id);
        _refreshAllData();
        
        if (mounted) {
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
  }

  void _refreshAllData() {
    _refreshLessonData();
    ref.invalidate(unlockedLessonsProvider);
    ref.invalidate(subjectsNotifierProvider);
  }
}