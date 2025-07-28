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
import 'package:qvise/features/content/presentation/providers/content_error_handler.dart';
import 'package:qvise/features/content/presentation/widgets/browse_subject_card.dart';
import 'package:qvise/features/content/presentation/widgets/topic_tile.dart';
import 'package:qvise/features/content/presentation/widgets/lesson_card.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import 'package:intl/intl.dart';

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
        // The title changes based on the navigation level
        title: Text(
          _selectedTopic ?? _selectedSubject ?? 'Browse Subjects',
          style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        // The back button appears only when navigating into topics or lessons
        leading: (_selectedSubject != null)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_selectedTopic != null) {
                      _selectedTopic = null; // Go back from lessons to topics
                    } else {
                      _selectedSubject = null; // Go back from topics to subjects
                    }
                  });
                },
              )
            : null,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      // Use an AnimatedSwitcher for smoother transitions between views
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentView(isOnline),
      ),
    );
  }
  
  // This helper determines which view to show
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
    final subjectsAsync = ref.watch(subjectsNotifierProvider).handleError(ref);

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
      loading: () =>
          const ContentLoadingWidget(message: 'Loading subjects...'),
      error: (error, stack) => _buildErrorView(
        message: _getErrorMessage(error), 
        onRetry: () => ref.invalidate(subjectsNotifierProvider),
      ),
    );
  }

  Widget _buildTopicsView(String subjectName, bool isOnline) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName)).handleError(ref);

    return Column(
      children: [
        _buildBreadcrumb(context, subjectName: subjectName),
        Expanded(
          child: topicsAsync.when(
            data: (topics) {
              if (topics.isEmpty) {
                return EmptyContentWidget(
                  icon: Icons.topic_outlined,
                  title: 'No Topics Yet',
                  description:
                      'Create a lesson in this subject to add topics!',
                  buttonText: 'Go to Create',
                  onButtonPressed: () {
                    ref.read(currentTabIndexProvider.notifier).state =
                        TabIndex.create;
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(topicsNotifierProvider(subjectName).notifier)
                    .refresh(),
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
    final lessonsAsync = ref.watch(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName)).handleError(ref);

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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FlashcardPreviewScreen(
                                lessonId: lesson.id,
                                allowEditing: false,
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
                  fontWeight: FontWeight.bold,
                  color: context.errorColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Type CONFIRM to delete:',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: confirmController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Type CONFIRM here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                ),
              ),
            ] else
              Text(
                'This action cannot be undone.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.errorColor,
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
              if (hasLockedLessons && confirmController.text != 'CONFIRM') {
                if (context.mounted) {
                  _showErrorSnackBar(context, 'Please type CONFIRM to delete');
                }
                return;
              }

              Navigator.pop(dialogContext);

              try {
                await ref.read(subjectsNotifierProvider.notifier).deleteSubject(subject.name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subject deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final errorMessage = _getErrorMessage(e);
                  _showErrorSnackBar(context, errorMessage);
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

  void _showDeleteTopicDialog(BuildContext context, WidgetRef ref, String subjectName, Topic topic) async {
    final allLessons = await ref.read(contentRepositoryProvider).getLessonsByTopic(subjectName, topic.name);
    bool hasLockedLessons = false;
    allLessons.fold((l) => null, (r) => hasLockedLessons = r.any((lesson) => lesson.isLocked));

    final TextEditingController confirmController = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete "${topic.name}"?',
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
              child: Text(
                '• ${topic.lessonCount} lessons\n• All flashcards in these lessons',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.errorDark,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (hasLockedLessons) ...[
              Text(
                'This topic contains locked lessons.',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.errorColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Type CONFIRM to delete:',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: confirmController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Type CONFIRM here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                ),
              ),
            ] else
              Text(
                'This action cannot be undone.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.errorColor,
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
              if (hasLockedLessons && confirmController.text != 'CONFIRM') {
                if(context.mounted) {
                  _showErrorSnackBar(context, 'Please type CONFIRM to delete');
                }
                return;
              }

              Navigator.pop(dialogContext);

              try {
                await ref.read(topicsNotifierProvider(subjectName).notifier).deleteTopic(topic.name);
                if(context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Topic deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if(context.mounted) {
                  final errorMessage = _getErrorMessage(e);
                  _showErrorSnackBar(context, errorMessage);
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

  void _showDeleteLessonDialog(BuildContext context, WidgetRef ref, Lesson lesson) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Lesson?',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
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
              child: Text(
                'This will also delete all flashcards in this lesson.\n\nThis action cannot be undone.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.errorDark,
                  height: 1.5,
                ),
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

              try {
                await ref.read(lessonsNotifierProvider(subjectName: lesson.subjectName, topicName: lesson.topicName).notifier).deleteLesson(lesson.id);
                if(context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lesson deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if(context.mounted) {
                  final errorMessage = _getErrorMessage(e);
                  _showErrorSnackBar(context, errorMessage);
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

  Widget _buildErrorView({required String message, required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Utility method to extract user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is AppFailure) {
      return error.userFriendlyMessage;
    } else if (error is ContentError) {
      return error.userFriendlyMessage;
    } else if (error is String) {
      return error;
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Utility method to show error snackbars consistently
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}