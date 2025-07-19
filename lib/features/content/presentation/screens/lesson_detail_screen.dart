// lib/features/content/presentation/screens/lesson_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/files/presentation/widgets/file_list_widget.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import 'package:qvise/core/theme/app_colors.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen>
    with TickerProviderStateMixin {
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
          return Scaffold(
            appBar: AppBar(title: const Text('Lesson Not Found')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: AppSpacing.md),
                  Text('Lesson not found', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.displayTitle,
                  style: const TextStyle(fontSize: 18),
                ),
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
                onPressed: () => _showLessonInfo(context, lesson),
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
                      const Text('Flashcards'),
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
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
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
      ),
    );
  }

  Widget _buildFlashcardsTab(lesson) {
    final flashcardsAsync = ref.watch(flashcardsByLessonProvider(widget.lessonId));

    return flashcardsAsync.when(
      data: (flashcards) {
        if (flashcards.isEmpty) {
          return _buildEmptyFlashcardsState(lesson);
        }

        return Column(
          children: [
            // Quick actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToCreateFlashcard(lesson),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Flashcard'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToPreviewFlashcards(lesson),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Preview All'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Flashcard statistics
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', '${flashcards.length}', Icons.style),
                  _buildStatItem(
                    'Favorites',
                    '${flashcards.where((f) => f.isFavorite).length}',
                    Icons.star,
                  ),
                  _buildStatItem(
                    'Reviewed',
                    '${flashcards.where((f) => f.reviewCount > 0).length}',
                    Icons.check_circle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Flashcard list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: flashcards.length,
                itemBuilder: (context, index) {
                  final flashcard = flashcards[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Color(int.parse(flashcard.tag.color.substring(1), radix: 16) + 0xFF000000)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: Text(
                          flashcard.tag.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      title: Text(
                        flashcard.frontContent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        flashcard.tag.name,
                        style: TextStyle(color: context.textSecondaryColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (flashcard.isFavorite)
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.chevron_right,
                            color: context.textSecondaryColor,
                          ),
                        ],
                      ),
                      onTap: () => _navigateToEditFlashcard(lesson, flashcard),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading flashcards: $error'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => ref.refresh(flashcardsByLessonProvider(widget.lessonId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesTab(lesson) {
    return FileListWidget(lessonId: widget.lessonId);
  }

  Widget _buildEmptyFlashcardsState(lesson) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style,
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
              'Create your first flashcard for this lesson',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateFlashcard(lesson),
              icon: const Icon(Icons.add),
              label: const Text('Create Flashcard'),
            ),
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

  void _navigateToCreateFlashcard(lesson) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: widget.lessonId,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
        ref.invalidate(flashcardCountProvider(widget.lessonId));
      }
    });
  }

  void _navigateToEditFlashcard(lesson, flashcard) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: widget.lessonId,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
          flashcardToEdit: flashcard,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
      }
    });
  }

  void _navigateToPreviewFlashcards(lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPreviewScreen(
          lessonId: widget.lessonId,
          allowEditing: true,
        ),
      ),
    ).then((_) {
      // Refresh data when returning
      ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
    });
  }

  void _showLessonInfo(BuildContext context, lesson) {
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
            _buildInfoRow('Proficiency', '${(lesson.proficiency * 100).toInt()}%'),
            _buildInfoRow('Review Stage', '${lesson.reviewStage}'),
            if (lesson.isLocked) 
              _buildInfoRow('Status', 'Locked for Review'),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}