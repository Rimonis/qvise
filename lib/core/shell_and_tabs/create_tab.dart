// lib/core/shell and tabs/create_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/screens/create_lesson_screen.dart';
import 'package:qvise/features/content/presentation/screens/lesson_screen.dart';
import 'package:qvise/features/content/presentation/widgets/unlocked_lesson_card.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class CreateTab extends ConsumerStatefulWidget {
  const CreateTab({super.key});

  @override
  ConsumerState<CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends ConsumerState<CreateTab> {
  @override
  Widget build(BuildContext context) {
    final unlockedLessonsAsync = ref.watch(unlockedLessonsProvider);
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: isOnline ? _navigateToCreateLesson : null,
            icon: const Icon(Icons.add),
            tooltip: 'Create New Lesson',
          ),
        ],
      ),
      body: unlockedLessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () => ref.refresh(unlockedLessonsProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: AppSpacing.screenPaddingAll,
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlocked Lessons',
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Continue working on your lessons or create a new one',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = lessons[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: UnlockedLessonCard(
                            lesson: lesson,
                            onTap: () => _navigateToLesson(lesson),
                            onLessonUpdated: () => _refreshAfterLessonUpdate(lesson),
                          ),
                        );
                      },
                      childCount: lessons.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading lessons...'),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
      floatingActionButton: isOnline
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateLesson,
              icon: const Icon(Icons.add),
              label: const Text('New Lesson'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return EmptyContentWidget(
      icon: Icons.create,
      title: 'No Lessons Yet',
      description: 'Create your first lesson to start learning!',
      buttonText: 'Create Lesson',
      onButtonPressed: _navigateToCreateLesson,
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Error Loading Lessons',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(unlockedLessonsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateLesson() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateLessonScreen(),
      ),
    );

    // If a lesson was created, refresh the UI
    if (result == true) {
      _refreshAfterLessonCreation();
    }
  }

  // Updated to use unified LessonScreen
  void _navigateToLesson(Lesson lesson) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(lessonId: lesson.id),
      ),
    );

    // Refresh when returning from lesson screen
    if (result == true) {
      _refreshAfterLessonUpdate(lesson);
    }
  }

  void _refreshAfterLessonCreation() {
    // Invalidate all relevant providers to refresh the UI
    ref.invalidate(unlockedLessonsProvider);
    ref.invalidate(subjectsNotifierProvider);
    // Also invalidate any cached subject/topic providers
    // Fixed: Changed from named parameter to positional parameter
    ref.invalidate(topicsNotifierProvider);
    ref.invalidate(lessonsNotifierProvider);
    
    // Show success message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson created successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _refreshAfterLessonUpdate(Lesson lesson) {
    // Refresh providers related to the specific lesson
    ref.invalidate(unlockedLessonsProvider);
    ref.invalidate(lessonProvider(lesson.id));
    
    // Also refresh subject/topic level providers
    ref.invalidate(subjectsNotifierProvider);
    // Fixed: Changed from named parameter to positional parameter
    ref.invalidate(topicsNotifierProvider(lesson.subjectName));
    ref.invalidate(lessonsNotifierProvider(subjectName: lesson.subjectName, topicName: lesson.topicName));
  }
}