// lib/core/shell and tabs/browse_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
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
import 'package:qvise/features/content/presentation/screens/lesson_detail_screen.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/features/files/presentation/widgets/file_list_item.dart';
import 'package:qvise/core/theme/app_spacing.dart';

class BrowseTab extends ConsumerStatefulWidget {
  const BrowseTab({super.key});

  @override
  ConsumerState<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<BrowseTab> with TickerProviderStateMixin {
  String? _selectedSubject;
  String? _selectedTopic;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;

    if (_selectedSubject == null) {
      return _buildMainBrowseView(isOnline);
    } else if (_selectedTopic == null) {
      return _buildTopicsView(_selectedSubject!, isOnline);
    } else {
      return _buildLessonsView(_selectedSubject!, _selectedTopic!, isOnline);
    }
  }

  Widget _buildMainBrowseView(bool isOnline) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Subjects'),
            Tab(icon: Icon(Icons.star), text: 'Starred Flashcards'),
            Tab(icon: Icon(Icons.star), text: 'Starred Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubjectsView(isOnline),
          _buildStarredFlashcardsView(),
          _buildStarredFilesView(),
        ],
      ),
    );
  }

  Widget _buildSubjectsView(bool isOnline) {
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
                  onTap: () {
                    setState(() {
                      _selectedSubject = subject.name;
                    });
                  },
                  onDelete: isOnline ? () => _showDeleteSubjectDialog(subject) : null,
                ),
              );
            },
          ),
        );
      },
      loading: () => const ContentLoadingWidget(),
      error: (error, stack) => _buildErrorWidget(
        'Failed to load subjects',
        error,
        () => ref.read(subjectsNotifierProvider.notifier).refresh(),
      ),
    );
  }

  Widget _buildStarredFlashcardsView() {
    // This would use your existing starred flashcards provider
    // For now, showing a placeholder
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey),
          SizedBox(height: AppSpacing.md),
          Text(
            'Starred Flashcards',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Star flashcards to see them here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStarredFilesView() {
    final starredFiles = ref.watch(starredFilesProvider);

    return starredFiles.when(
      data: (files) {
        if (files.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 64, color: Colors.grey),
                SizedBox(height: AppSpacing.md),
                Text(
                  'No Starred Files',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Star files in your lessons to see them here',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(starredFilesProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return FileListItem(
                file: files[index],
                onDeleted: () {
                  ref.read(starredFilesProvider.notifier).refresh();
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(
        'Failed to load starred files',
        error,
        () => ref.read(starredFilesProvider.notifier).refresh(),
      ),
    );
  }

  Widget _buildTopicsView(String subjectName, bool isOnline) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName));

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedSubject = null),
        ),
      ),
      body: topicsAsync.when(
        data: (topics) {
          if (topics.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.topic,
              title: 'No Topics Yet',
              description: 'Create your first lesson in this subject!',
              buttonText: 'Go to Create',
              onButtonPressed: () {
                ref.read(currentTabIndexProvider.notifier).state = 1; // Create tab
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
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TopicTile(
                    topic: topic,
                    onTap: () {
                      setState(() {
                        _selectedTopic = topic.name;
                      });
                    },
                    onDelete: isOnline ? () => _showDeleteTopicDialog(topic) : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ContentLoadingWidget(),
        error: (error, stack) => _buildErrorWidget(
          'Failed to load topics',
          error,
          () => ref.read(topicsNotifierProvider(subjectName).notifier).refresh(),
        ),
      ),
    );
  }

  Widget _buildLessonsView(String subjectName, String topicName, bool isOnline) {
    final lessonsAsync = ref.watch(lessonsNotifierProvider(subjectName, topicName));

    return Scaffold(
      appBar: AppBar(
        title: Text(topicName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedTopic = null),
        ),
      ),
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.library_books,
              title: 'No Lessons Yet',
              description: 'Create your first lesson in this topic!',
              buttonText: 'Go to Create',
              onButtonPressed: () {
                ref.read(currentTabIndexProvider.notifier).state = 1; // Create tab
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(lessonsNotifierProvider(subjectName, topicName).notifier).refresh(),
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
                    onDelete: isOnline ? () => _showDeleteLessonDialog(lesson) : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ContentLoadingWidget(),
        error: (error, stack) => _buildErrorWidget(
          'Failed to load lessons',
          error,
          () => ref.read(lessonsNotifierProvider(subjectName, topicName).notifier).refresh(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String title, Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
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

  void _navigateToLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lessonId: lesson.id),
      ),
    );
  }

  void _showDeleteSubjectDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}" and all its content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(deleteSubjectProvider).call(subject.name);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        content: Text('Are you sure you want to delete "${topic.name}" and all its lessons?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(deleteTopicProvider).call(
                subjectName: topic.subjectName,
                topicName: topic.name,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        content: Text('Are you sure you want to delete "${lesson.displayTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(deleteLessonProvider).call(lesson.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}