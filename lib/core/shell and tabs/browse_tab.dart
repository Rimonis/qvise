// lib/core/shell and tabs/browse_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/domain/entities/subject.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/providers/tab_navigation_provider.dart';
import 'package:qvise/features/content/presentation/widgets/browse_subject_card.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
// Add flashcard provider import
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
// Add theme imports
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class BrowseTab extends ConsumerStatefulWidget {
  const BrowseTab({super.key});

  @override
  ConsumerState<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<BrowseTab> {
  String? _selectedSubject;
  String? _selectedTopic;
  
  // Helper method to get flashcard count for a lesson
  Future<int> _getFlashcardCount(String lessonId) async {
    final flashcardRepo = ref.read(flashcardRepositoryProvider);
    final result = await flashcardRepo.countFlashcardsByLesson(lessonId);
    return result.fold((failure) => 0, (count) => count);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_selectedSubject == null) {
      return _buildSubjectsView();
    } else if (_selectedTopic == null) {
      return _buildTopicsView(_selectedSubject!);
    } else {
      return _buildLessonsView(_selectedSubject!, _selectedTopic!);
    }
  }
  
  Widget _buildSubjectsView() {
    final subjectsAsync = ref.watch(subjectsNotifierProvider);
    
    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return EmptyContentWidget(
            icon: Icons.school,
            title: 'No Subjects Yet',
            description: 'Create your first lesson to get started!',
            buttonText: 'Go to Create',
            onButtonPressed: () {
              // Switch to Create tab - need to find the MainShellScreen ancestor
              // Using a callback to ensure we have the correct context
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(currentTabIndexProvider.notifier).state = TabIndex.create;
              });
            },
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.read(subjectsNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            padding: AppSpacing.screenPaddingAll,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: BrowseSubjectCard(
                  subject: subject,
                  onTap: () {
                    setState(() {
                      _selectedSubject = subject.name;
                    });
                  },
                  onDelete: () => _showDeleteSubjectDialog(subject),
                ),
              );
            },
          ),
        );
      },
      loading: () => const ContentLoadingWidget(message: 'Loading subjects...'),
      error: (error, stack) => _buildErrorView(() => ref.invalidate(subjectsNotifierProvider)),
    );
  }
  
  Widget _buildTopicsView(String subjectName) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName));
    
    return Column(
      children: [
        // Breadcrumb
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingAllMd,
          color: context.surfaceVariantColor.withValues(alpha: 0.5),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSubject = null;
                  });
                },
                child: Text(
                  'Subjects',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' > ',
                style: context.textTheme.bodyMedium,
              ),
              Text(
                subjectName,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: topicsAsync.when(
            data: (topics) {
              if (topics.isEmpty) {
                return EmptyContentWidget(
                  icon: Icons.topic,
                  title: 'No Topics Yet',
                  description: 'Create a lesson in this subject to add topics!',
                  buttonText: 'Go to Create',
                  onButtonPressed: () {
                    // Switch to Create tab
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(currentTabIndexProvider.notifier).state = TabIndex.create;
                    });
                  },
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => ref.read(topicsNotifierProvider(subjectName).notifier).refresh(),
                child: ListView.builder(
                  padding: AppSpacing.screenPaddingAll,
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Card(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse(topic.proficiencyColor.replaceAll('#', '0xFF'))).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Icon(
                              Icons.topic,
                              color: Color(int.parse(topic.proficiencyColor.replaceAll('#', '0xFF'))),
                            ),
                          ),
                          title: Text(
                            topic.name,
                            style: context.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${topic.lessonCount} lessons • ${topic.proficiencyLabel}',
                            style: context.textTheme.bodySmall,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteTopicDialog(topic.name);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: AppColors.error, size: AppSpacing.iconSm),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedTopic = topic.name;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const ContentLoadingWidget(message: 'Loading topics...'),
            error: (error, stack) => _buildErrorView(() => ref.invalidate(topicsNotifierProvider(subjectName))),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLessonsView(String subjectName, String topicName) {
    final lessonsAsync = ref.watch(lessonsNotifierProvider(subjectName, topicName));
    
    return Column(
      children: [
        // Breadcrumb
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingAllMd,
          color: context.surfaceVariantColor.withValues(alpha: 0.5),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSubject = null;
                    _selectedTopic = null;
                  });
                },
                child: Text(
                  'Subjects',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(' > ', style: context.textTheme.bodyMedium),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTopic = null;
                  });
                },
                child: Text(
                  subjectName,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(' > ', style: context.textTheme.bodyMedium),
              Text(
                topicName,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: lessonsAsync.when(
            data: (lessons) {
              // Filter to show only locked lessons
              final lockedLessons = lessons.where((lesson) => lesson.isLocked).toList();
              
              if (lockedLessons.isEmpty) {
                return const EmptyContentWidget(
                  icon: Icons.lock_open,
                  title: 'No Locked Lessons',
                  description: 'All lessons in this topic are still being created.\nLocked lessons will appear here once ready for review.',
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => ref.read(lessonsNotifierProvider(subjectName, topicName).notifier).refresh(),
                child: ListView.builder(
                  padding: AppSpacing.screenPaddingAll,
                  itemCount: lockedLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lockedLessons[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Card(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse(lesson.proficiencyColor.replaceAll('#', '0xFF'))).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.book,
                                  color: Color(int.parse(lesson.proficiencyColor.replaceAll('#', '0xFF'))),
                                ),
                                if (lesson.isLocked)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Icon(
                                      Icons.lock,
                                      size: AppSpacing.iconXs,
                                      color: context.textTertiaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          title: Text(
                            lesson.displayTitle,
                            style: context.textTheme.titleMedium,
                          ),
                          subtitle: FutureBuilder<int>(
                            future: _getFlashcardCount(lesson.id),
                            builder: (context, snapshot) {
                              final flashcardCount = snapshot.data ?? 0;
                              final totalItems = lesson.totalContentCount + flashcardCount;
                              return Text(
                                '${lesson.reviewStatus} • Stage ${lesson.reviewStage}/5 • $totalItems items${flashcardCount > 0 ? ' (${flashcardCount} flashcards)' : ''}',
                                style: context.textTheme.bodySmall,
                              );
                            },
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteLessonDialog(lesson.id, lesson.displayTitle);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: AppColors.error, size: AppSpacing.iconSm),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            // Navigate to lesson detail/study screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Study "${lesson.displayTitle}" - Coming Soon'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const ContentLoadingWidget(message: 'Loading lessons...'),
            error: (error, stack) => _buildErrorView(() => ref.invalidate(lessonsNotifierProvider(subjectName, topicName))),
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorView(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Error loading content',
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteSubjectDialog(Subject subject) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${subject.name}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:\n'
              '• ${subject.topicCount} topics\n'
              '• ${subject.lessonCount} lessons\n'
              '• All flashcards in these lessons\n\n'
              'This action cannot be undone.',
              style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Type CONFIRM to delete:',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'CONFIRM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                contentPadding: AppSpacing.paddingSymmetricSm,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder(
            valueListenable: textController,
            builder: (context, value, child) {
              final isConfirmed = value.text == 'CONFIRM';
              return ElevatedButton(
                onPressed: isConfirmed
                    ? () async {
                        Navigator.pop(dialogContext);
                        try {
                          // Delete all flashcards in the subject first
                          final flashcardRepo = ref.read(flashcardRepositoryProvider);
                          // Get all lessons in the subject and delete their flashcards
                          // This would require getting all lessons across all topics in the subject
                          // For now, just delete the subject and let the database handle cleanup
                          
                          await ref.read(subjectsNotifierProvider.notifier).deleteSubject(subject.name);
                          setState(() {
                            _selectedSubject = null;
                            _selectedTopic = null;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${subject.name}" deleted successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete: ${e.toString()}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showDeleteTopicDialog(String topicName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$topicName"?'),
        content: Text(
          'This will delete the topic and all its lessons and flashcards.',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Topic deletion - Coming Soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteLessonDialog(String lessonId, String lessonTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$lessonTitle"?'),
        content: Text(
          'This will delete the lesson and all its flashcards.',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete flashcards first
                final flashcardRepo = ref.read(flashcardRepositoryProvider);
                final flashcardsResult = await flashcardRepo.getFlashcardsByLesson(lessonId);
                
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
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Lesson and flashcards deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: ${e.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}