// lib/core/shell and tabs/browse_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/features/content/domain/entities/subject.dart';
import 'package:qvise/features/content/domain/entities/topic.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/providers/tab_navigation_provider.dart';
import 'package:qvise/features/content/presentation/widgets/browse_subject_card.dart';
import 'package:qvise/features/content/presentation/widgets/topic_tile.dart';
import 'package:qvise/features/content/presentation/widgets/lesson_card.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/content/presentation/screens/lesson_screen.dart';
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
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;

    // Navigate based on selection state
    if (_selectedSubject == null) {
      return _buildSubjectsView(isOnline);
    } else if (_selectedTopic == null) {
      return _buildTopicsView(_selectedSubject!, isOnline);
    } else {
      return _buildLessonsView(_selectedSubject!, _selectedTopic!, isOnline);
    }
  }

  // Main view showing all subjects
  Widget _buildSubjectsView(bool isOnline) {
    final subjectsAsync = ref.watch(subjectsNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        centerTitle: false,
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.school,
              title: 'No Subjects Yet',
              description: 'Create your first lesson to get started!',
              buttonText: 'Go to Create',
              onButtonPressed: () {
                ref.read(currentTabIndexProvider.notifier).state = 1; // Create tab
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
                    onTap: () => setState(() => _selectedSubject = subject.name),
                    onDelete: isOnline 
                        ? () => _showDeleteSubjectDialog(subject) 
                        : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading subjects...'),
        error: (error, stack) => _buildErrorView(
          error.toString(),
          () => ref.invalidate(subjectsNotifierProvider),
        ),
      ),
    );
  }

  // View for topics within a selected subject
  Widget _buildTopicsView(String subjectName, bool isOnline) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName: subjectName));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedSubject = null),
        ),
        title: Text(subjectName),
      ),
      body: topicsAsync.when(
        data: (topics) {
          if (topics.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.topic,
              title: 'No Topics Yet',
              description: 'Create a lesson in this subject to add topics!',
              buttonText: 'Go to Create',
              onButtonPressed: () {
                ref.read(currentTabIndexProvider.notifier).state = 1; // Create tab
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(topicsNotifierProvider(subjectName: subjectName).notifier).refresh(),
            child: ListView.builder(
              padding: AppSpacing.screenPaddingAll,
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TopicTile(
                    topic: topic,
                    onTap: () => setState(() => _selectedTopic = topic.name),
                    onDelete: isOnline 
                        ? () => _showDeleteTopicDialog(topic) 
                        : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading topics...'),
        error: (error, stack) => _buildErrorView(
          error.toString(),
          () => ref.invalidate(topicsNotifierProvider(subjectName: subjectName)),
        ),
      ),
    );
  }

  // View for lessons within a selected topic
  Widget _buildLessonsView(String subjectName, String topicName, bool isOnline) {
    final lessonsAsync = ref.watch(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedTopic = null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topicName, style: const TextStyle(fontSize: 18)),
            Text(
              subjectName,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.book,
              title: 'No Lessons Yet',
              description: 'Create your first lesson in this topic!',
              buttonText: 'Go to Create',
              onButtonPressed: () {
                ref.read(currentTabIndexProvider.notifier).state = 1; // Create tab
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName).notifier).refresh(),
            child: ListView.builder(
              padding: AppSpacing.screenPaddingAll,
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: LessonCard(
                    lesson: lesson,
                    onTap: () => _navigateToLesson(lesson),
                    onDelete: isOnline 
                        ? () => _showDeleteLessonDialog(lesson) 
                        : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading lessons...'),
        error: (error, stack) => _buildErrorView(
          error.toString(),
          () => ref.invalidate(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName)),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.textTertiaryColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
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

  // Navigation - now uses unified LessonScreen
  void _navigateToLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(lessonId: lesson.id),
      ),
    ).then((_) {
      // Refresh data when returning from lesson screen
      ref.invalidate(lessonsNotifierProvider(subjectName: _selectedSubject!, topicName: _selectedTopic!));
    });
  }

  void _showDeleteSubjectDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"? This will delete all topics and lessons in this subject.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(subjectsNotifierProvider.notifier).deleteSubject(subject.name);
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Subject "${subject.name}" deleted')),
                      );
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete subject: $e')),
                      );
                    }
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTopicDialog(Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete "${topic.name}"? This will delete all lessons in this topic.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(topicsNotifierProvider(subjectName: _selectedSubject!).notifier).deleteTopic(topic.name);
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Topic "${topic.name}" deleted')),
                      );
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete topic: $e')),
                      );
                    }
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLessonDialog(Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.displayTitle}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(lessonsNotifierProvider(subjectName: _selectedSubject!, topicName: _selectedTopic!).notifier).deleteLesson(lesson.id);
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lesson "${lesson.displayTitle}" deleted')),
                      );
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete lesson: $e')),
                      );
                    }
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}