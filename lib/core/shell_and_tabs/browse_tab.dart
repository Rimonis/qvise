// lib/core/shell_and_tabs/browse_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/entities/subject.dart';
import 'package:qvise/features/content/domain/entities/topic.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/providers/content_providers.dart';
import 'package:qvise/features/content/presentation/providers/tab_navigation_provider.dart';

import 'package:qvise/features/content/presentation/widgets/browse_subject_card.dart';
import 'package:qvise/features/content/presentation/widgets/topic_tile.dart';
import 'package:qvise/features/content/presentation/widgets/lesson_card.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/content/presentation/screens/lesson_screen.dart'; // ADD THIS LINE

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

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider).asData?.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedTopic ?? _selectedSubject ?? 'Browse Subjects',
          style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: (_selectedSubject != null)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_selectedTopic != null) {
                      _selectedTopic = null;
                    } else {
                      _selectedSubject = null;
                    }
                  });
                },
              )
            : null,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentView(isOnline),
      ),
    );
  }

  Widget _buildCurrentView(bool isOnline) {
    if (_selectedSubject == null) {
      return _buildSubjectsView(isOnline);
    } else if (_selectedTopic == null) {
      return _buildTopicsView(_selectedSubject!, isOnline);
    } else {
      return _buildLessonsView(_selectedSubject!, _selectedTopic!, isOnline);
    }
  }

  Widget _buildSubjectsView(bool isOnline) {
    final subjectsAsync = ref.watch(subjectsNotifierProvider);

    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return EmptyContentWidget(
            icon: Icons.school_outlined,
            title: 'No Subjects Yet',
            description: 'Go to the Create tab to make your first lesson!',
            buttonText: 'Go to Create',
            onButtonPressed: () {
              ref.read(currentTabIndexProvider.notifier).state = TabIndex.create;
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(subjectsNotifierProvider.notifier).refresh(),
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
                  onDelete: isOnline
                      ? () => _showDeleteSubjectDialog(context, ref, subject)
                      : null,
                ),
              );
            },
          ),
        );
      },
      loading: () => const ContentLoadingWidget(message: 'Loading subjects...'),
      error: (error, stack) => _buildErrorView(
        message: _getErrorMessage(error),
        onRetry: () => ref.invalidate(subjectsNotifierProvider),
      ),
    );
  }

  Widget _buildTopicsView(String subjectName, bool isOnline) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName));

    return Column(
      children: [
        _buildBreadcrumb(context, subjectName: subjectName),
        Expanded(
          child: topicsAsync.when(
            data: (topics) {
              if (topics.isEmpty) {
                return const EmptyContentWidget(
                  icon: Icons.topic_outlined,
                  title: 'No Topics Yet',
                  description: 'Create your first topic to organize lessons within this subject.',
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TopicTile(
                        topic: topic,
                        onTap: () {
                          setState(() {
                            _selectedTopic = topic.name;
                          });
                        },
                        onDelete: isOnline
                            ? () => _showDeleteTopicDialog(context, ref, subjectName, topic)
                            : null,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () =>
                const ContentLoadingWidget(message: 'Loading topics...'),
            error: (error, stack) => _buildErrorView(
              message: _getErrorMessage(error),
              onRetry: () => ref.invalidate(topicsNotifierProvider(subjectName)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsView(String subjectName, String topicName, bool isOnline) {
    final lessonsAsync = ref.watch(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName));

    return Column(
      children: [
        _buildBreadcrumb(context, subjectName: subjectName, topicName: topicName),
        Expanded(
          child: lessonsAsync.when(
            data: (lessons) {
              final lockedLessons =
                  lessons.where((lesson) => lesson.isLocked).toList();

              if (lockedLessons.isEmpty) {
                return const EmptyContentWidget(
                  icon: Icons.lock_open_outlined,
                  title: 'No Locked Lessons',
                  description:
                      'All lessons in this topic are still being created.\nLocked lessons will appear here once ready for review.',
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(
                        lessonsNotifierProvider(subjectName: subjectName, topicName: topicName).notifier)
                    .refresh(),
                child: ListView.builder(
                  padding: AppSpacing.screenPaddingAll,
                  itemCount: lockedLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lockedLessons[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: LessonCard(
                        lesson: lesson,
                        onTap: () {
                          // ONLY CHANGE: Replace FlashcardPreviewScreen with LessonScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonScreen(
                                lessonId: lesson.id,
                              ),
                            ),
                          );
                        },
                        onDelete: isOnline
                            ? () => _showDeleteLessonDialog(context, ref, lesson)
                            : null,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () =>
                const ContentLoadingWidget(message: 'Loading lessons...'),
            error: (error, stack) => _buildErrorView(
              message: _getErrorMessage(error),
              onRetry: () => ref.invalidate(
                lessonsNotifierProvider(subjectName: subjectName, topicName: topicName)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(BuildContext context, {String? subjectName, String? topicName}) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAllMd,
      color: context.surfaceVariantColor.withValues(alpha: 0.5),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
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
          if (subjectName != null) ...[
            Text(' > ', style: context.textTheme.bodyMedium),
            GestureDetector(
              onTap: topicName == null ? null : () {
                setState(() {
                  _selectedTopic = null;
                });
              },
              child: Text(
                subjectName,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: topicName == null ? FontWeight.bold : FontWeight.normal,
                  color: topicName != null ? context.primaryColor : null,
                  decoration: topicName != null ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ],
          if (topicName != null) ...[
            Text(' > ', style: context.textTheme.bodyMedium),
            Text(
              topicName,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteSubjectDialog(BuildContext context, WidgetRef ref, Subject subject) async {
    final allLessons = await ref.read(contentRepositoryProvider).getAllLessons();
    bool hasLockedLessons = false;
    allLessons.fold(
        (l) => null,
        (r) => hasLockedLessons = r.any((lesson) =>
            lesson.subjectName == subject.name && lesson.isLocked));

    final TextEditingController confirmController = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete "${subject.name}"?',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.paddingAllSm,
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: context.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${subject.topicCount} topics',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.errorDark,
                    ),
                  ),
                  Text(
                    '• ${subject.lessonCount} lessons',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.errorDark,
                    ),
                  ),
                  Text(
                    '• All flashcards in these lessons',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.errorDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (hasLockedLessons) ...[
              Text(
                'This subject contains locked lessons.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const Text(
              'Type the subject name to confirm:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: subject.name,
                border: const OutlineInputBorder(),
                contentPadding: AppSpacing.paddingAllSm,
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
              if (confirmController.text.trim() == subject.name) {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(contentRepositoryProvider).deleteSubject(subject.name);
                  ref.invalidate(subjectsNotifierProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Subject "${subject.name}" deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete subject: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Subject name does not match')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteTopicDialog(BuildContext context, WidgetRef ref, String subjectName, Topic topic) async {
    final allLessons = await ref.read(contentRepositoryProvider).getAllLessons();
    bool hasLockedLessons = false;
    allLessons.fold(
        (l) => null,
        (r) => hasLockedLessons = r.any((lesson) =>
            lesson.subjectName == subjectName &&
            lesson.topicName == topic.name && lesson.isLocked));

    final TextEditingController confirmController = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete "${topic.name}"?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete all ${topic.lessonCount} lessons in this topic.',
              style: const TextStyle(fontSize: 14),
            ),
            if (hasLockedLessons) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'This topic contains locked lessons.',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Type the topic name to confirm:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: topic.name,
                border: const OutlineInputBorder(),
                contentPadding: AppSpacing.paddingAllSm,
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
              if (confirmController.text.trim() == topic.name) {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(contentRepositoryProvider).deleteTopic(subjectName, topic.name);
                  ref.invalidate(topicsNotifierProvider(subjectName));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Topic "${topic.name}" deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete topic: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Topic name does not match')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteLessonDialog(BuildContext context, WidgetRef ref, Lesson lesson) async {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete "${lesson.displayTitle}"?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete this lesson and all its associated content.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'This lesson is locked and may be actively studied by users.',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
                contentPadding: AppSpacing.paddingAllSm,
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
              if (confirmController.text.trim() == 'DELETE') {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(contentRepositoryProvider).deleteLesson(lesson.id);
                  ref.invalidate(lessonsNotifierProvider(subjectName: lesson.subjectName, topicName: lesson.topicName));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lesson "${lesson.displayTitle}" deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete lesson: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please type "DELETE" to confirm')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView({required String message, required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.textSecondaryColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Oops! Something went wrong',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is AppFailure) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}