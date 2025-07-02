// lib/core/shell and tabs/create_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/screens/subject_selection_screen.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/content/presentation/widgets/unlocked_lesson_card.dart';
// Flashcard imports
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';

class CreateTab extends ConsumerStatefulWidget {
  const CreateTab({super.key});

  @override
  ConsumerState<CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends ConsumerState<CreateTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh lessons
      await ref.refresh(unlockedLessonsProvider);
      // Invalidate all flashcard count providers to refresh them
      ref.invalidate(flashcardCountProvider);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Helper method to get flashcard count for a lesson
  Future<int> _getFlashcardCount(String lessonId) async {
    final flashcardRepo = ref.read(flashcardRepositoryProvider);
    final result = await flashcardRepo.countFlashcardsByLesson(lessonId);
    return result.fold((failure) => 0, (count) => count);
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    final unlockedLessonsAsync = ref.watch(unlockedLessonsProvider);

    if (!isOnline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Internet connection required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please connect to the internet to create and edit lessons.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(networkStatusProvider.notifier).checkNow();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return unlockedLessonsAsync.when(
      data: (unlockedLessons) {
        if (unlockedLessons.isEmpty) {
          return EmptyContentWidget(
            icon: Icons.edit,
            title: 'Start Creating',
            description:
                'Create your first lesson and start building your knowledge base!',
            buttonText: 'Create Lesson',
            onButtonPressed: () => _navigateToSubjectSelection(context),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Work in Progress',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${unlockedLessons.length} unlocked ${unlockedLessons.length == 1 ? 'lesson' : 'lessons'} ready for editing',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange
                                    .withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Add content to your lessons, then lock them to start spaced repetition',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lessons list with flashcard integration
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = unlockedLessons[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildEnhancedLessonCard(lesson),
                        );
                      },
                      childCount: unlockedLessons.length,
                    ),
                  ),
                ),

                // Add lesson button at the end of the list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToSubjectSelection(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Lesson'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Bottom padding for lock button
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
          bottomSheet: _buildLockButton(context, ref, unlockedLessons),
        );
      },
      loading: () => const ContentLoadingWidget(message: 'Loading lessons...'),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(unlockedLessonsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEnhancedLessonCard(Lesson lesson) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Original lesson card content
          UnlockedLessonCard(
            lesson: lesson,
            onTap: () => _navigateToLessonEditor(lesson),
            onDelete: () => _showDeleteDialog(context, ref, lesson),
          ),
          
          // Flashcard actions section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.style,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Flashcards',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const Spacer(),
                    // Show flashcard count using FutureBuilder
                    FutureBuilder<int>(
                      future: _getFlashcardCount(lesson.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text(
                          '$count cards',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _createFlashcard(lesson),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: Colors.blue[300]!),
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<int>(
                        future: _getFlashcardCount(lesson.id),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return OutlinedButton.icon(
                            onPressed: count > 0 
                              ? () => _previewFlashcards(lesson)
                              : null,
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('Preview'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(
                                color: count > 0 
                                  ? Colors.blue[300]! 
                                  : Colors.grey[300]!,
                              ),
                              foregroundColor: count > 0 
                                ? Colors.blue[700] 
                                : Colors.grey[500],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Flashcard creation method
  void _createFlashcard(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: lesson.id,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
        ),
        fullscreenDialog: true, // This ensures proper overlay and hides parent FABs
      ),
    ).then((result) {
      // Refresh if flashcard was created
      if (result == true) {
        _handleRefresh();
      }
    });
  }

  // Flashcard preview method
  void _previewFlashcards(Lesson lesson) async {
    final flashcardRepo = ref.read(flashcardRepositoryProvider);
    final result = await flashcardRepo.getFlashcardsByLesson(lesson.id);
    
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load flashcards: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (flashcards) {
        if (flashcards.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No flashcards found for this lesson'),
            ),
          );
        } else {
          // TODO: Navigate to flashcard preview/study screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${flashcards.length} flashcards - Preview coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _navigateToLessonEditor(Lesson lesson) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "${lesson.displayTitle}" - Coming Soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToSubjectSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubjectSelectionScreen(),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Lesson lesson) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: Text(
          'Are you sure you want to delete "${lesson.displayTitle}"?\n\n'
          'This will also delete all flashcards in this lesson.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // First delete all flashcards for this lesson
                final flashcardRepo = ref.read(flashcardRepositoryProvider);
                final flashcardsResult = await flashcardRepo.getFlashcardsByLesson(lesson.id);
                
                await flashcardsResult.fold(
                  (failure) async {
                    // Continue even if we can't get flashcards
                  },
                  (flashcards) async {
                    // Delete all flashcards
                    for (final flashcard in flashcards) {
                      await flashcardRepo.deleteFlashcard(flashcard.id);
                    }
                  },
                );
                
                // Then delete the lesson
                await ref
                    .read(lessonsNotifierProvider(
                            lesson.subjectName, lesson.topicName)
                        .notifier)
                    .deleteLesson(lesson.id);
                    
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lesson and flashcards deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget? _buildLockButton(
      BuildContext context, WidgetRef ref, List<Lesson> unlockedLessons) {
    if (unlockedLessons.isEmpty) return null;

    final readyToLock =
        unlockedLessons.where((lesson) => lesson.totalContentCount > 0).toList();

    if (readyToLock.isEmpty && unlockedLessons.length < 2) {
      return null;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (readyToLock.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${readyToLock.length} ${readyToLock.length == 1 ? 'lesson' : 'lessons'} ready to lock',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: readyToLock.isNotEmpty
                    ? () => _showLockDialog(context, ref, readyToLock)
                    : null,
                icon: const Icon(Icons.lock),
                label: Text(
                  readyToLock.isEmpty
                      ? 'Add content to lessons first'
                      : 'Lock ${readyToLock.length} ${readyToLock.length == 1 ? 'Lesson' : 'Lessons'}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: readyToLock.isNotEmpty ? Colors.orange : null,
                  foregroundColor: readyToLock.isNotEmpty ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLockDialog(
      BuildContext context, WidgetRef ref, List<Lesson> readyToLock) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lock Lessons?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lock lessons and start spaced repetition?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: readyToLock
                      .map((lesson) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.book, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lesson.displayTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final flashcardCountAsync = ref.watch(flashcardCountProvider(lesson.id));
                                    return flashcardCountAsync.when(
                                      data: (flashcardCount) {
                                        final totalCount = lesson.totalContentCount + flashcardCount;
                                        return Text(
                                          '$totalCount items',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        );
                                      },
                                      loading: () => Text(
                                        '${lesson.totalContentCount}+ items',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      error: (_, __) => Text(
                                        '${lesson.totalContentCount} items',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once locked, lessons cannot be unlocked or edited',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Locked ${readyToLock.length} lessons - Feature Coming Soon'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
  }
}