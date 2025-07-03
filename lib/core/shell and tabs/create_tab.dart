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
// Theme imports
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

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
          padding: AppSpacing.screenPaddingAll,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: context.textTertiaryColor),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Internet connection required',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please connect to the internet to create and edit lessons.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                    margin: AppSpacing.screenPaddingAll,
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: context.primaryColor,
                              size: AppSpacing.iconLg,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Work in Progress',
                              style: context.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${unlockedLessons.length} unlocked ${unlockedLessons.length == 1 ? 'lesson' : 'lessons'} ready for editing',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: AppSpacing.paddingAllSm,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: AppSpacing.iconSm,
                                color: AppColors.warningDark,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Add content to your lessons, then lock them to start spaced repetition',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: AppColors.warningDark,
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
                  padding: AppSpacing.paddingHorizontalMd,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = unlockedLessons[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                    padding: AppSpacing.screenPaddingAll,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToSubjectSelection(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Lesson'),
                      style: OutlinedButton.styleFrom(
                        padding: AppSpacing.paddingVerticalMd,
                        side: BorderSide(color: context.primaryColor),
                        foregroundColor: context.primaryColor,
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
          padding: AppSpacing.screenPaddingAll,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium?.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.md),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusMedium),
                bottomRight: Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.style,
                      size: AppSpacing.iconSm,
                      color: AppColors.infoDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Flashcards',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.infoDark,
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
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.textTertiaryColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _createFlashcard(lesson),
                        icon: const Icon(Icons.add, size: AppSpacing.iconSm),
                        label: const Text('Create'),
                        style: OutlinedButton.styleFrom(
                          padding: AppSpacing.paddingVerticalSm,
                          side: BorderSide(color: AppColors.info),
                          foregroundColor: AppColors.infoDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FutureBuilder<int>(
                        future: _getFlashcardCount(lesson.id),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return OutlinedButton.icon(
                            onPressed: count > 0 
                              ? () => _previewFlashcards(lesson)
                              : null,
                            icon: const Icon(Icons.visibility, size: AppSpacing.iconSm),
                            label: const Text('Preview'),
                            style: OutlinedButton.styleFrom(
                              padding: AppSpacing.paddingVerticalSm,
                              side: BorderSide(
                                color: count > 0 
                                  ? AppColors.info 
                                  : context.borderColor,
                              ),
                              foregroundColor: count > 0 
                                ? AppColors.infoDark 
                                : context.textDisabledColor,
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
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load flashcards: ${failure.message}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          });
        }
      },
      (flashcards) {
        if (flashcards.isEmpty) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No flashcards found for this lesson'),
                  ),
                );
              }
            });
          }
        } else {
          // TODO: Navigate to flashcard preview/study screen
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Found ${flashcards.length} flashcards - Preview coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }
        }
      },
    );
  }

  void _navigateToLessonEditor(Lesson lesson) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edit "${lesson.displayTitle}" - Coming Soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
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
          style: context.textTheme.bodyMedium,
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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Lesson and flashcards deleted successfully'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
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
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: context.backgroundColor,
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
                padding: AppSpacing.paddingAllMd,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: AppSpacing.iconSm,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${readyToLock.length} ${readyToLock.length == 1 ? 'lesson' : 'lessons'} ready to lock',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.successDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
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
                  backgroundColor: readyToLock.isNotEmpty ? AppColors.warning : null,
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
        title: Text('Lock ${readyToLock.length} Lessons?'),
        content: Text(
          'This will lock the selected lessons and start spaced repetition scheduling.',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Locked ${readyToLock.length} lessons - Feature Coming Soon'),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
  }
}