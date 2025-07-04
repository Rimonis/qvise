// lib/core/shell and tabs/browse_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/domain/entities/subject.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/providers/tab_navigation_provider.dart';
import 'package:qvise/features/content/presentation/widgets/browse_subject_card.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
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
                ),
              );
            },
          ),
        );
      },
      loading: () =>
          const ContentLoadingWidget(message: 'Loading subjects...'),
      error: (error, stack) =>
          _buildErrorView(() => ref.invalidate(subjectsNotifierProvider)),
    );
  }

  Widget _buildTopicsView(String subjectName) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName));

    return Column(
      children: [
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
                    return Card(
                      child: ListTile(
                        title: Text(topic.name),
                        onTap: () {
                          setState(() {
                            _selectedTopic = topic.name;
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () =>
                const ContentLoadingWidget(message: 'Loading topics...'),
            error: (error, stack) => _buildErrorView(
                () => ref.invalidate(topicsNotifierProvider(subjectName))),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsView(String subjectName, String topicName) {
    final lessonsAsync =
        ref.watch(lessonsNotifierProvider(subjectName, topicName));

    return Column(
      children: [
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
              final lockedLessons =
                  lessons.where((lesson) => lesson.isLocked).toList();

              if (lockedLessons.isEmpty) {
                return const EmptyContentWidget(
                  icon: Icons.lock_open,
                  title: 'No Locked Lessons',
                  description:
                      'All lessons in this topic are still being created.\nLocked lessons will appear here once ready for review.',
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(
                        lessonsNotifierProvider(subjectName, topicName).notifier)
                    .refresh(),
                child: ListView.builder(
                  padding: AppSpacing.screenPaddingAll,
                  itemCount: lockedLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lockedLessons[index];
                    return Card(
                      child: ListTile(
                        title: Text(lesson.displayTitle),
                        trailing: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FlashcardPreviewScreen(lessonId: lesson.id),
                            ),
                          ),
                          child: const Text('Preview'),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () =>
                const ContentLoadingWidget(message: 'Loading lessons...'),
            error: (error, stack) => _buildErrorView(() => ref
                .invalidate(lessonsNotifierProvider(subjectName, topicName))),
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
            style:
                context.textTheme.titleMedium?.copyWith(color: AppColors.error),
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
}
