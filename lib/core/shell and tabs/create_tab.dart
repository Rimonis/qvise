// lib/core/shell and tabs/create_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/content/presentation/widgets/unlocked_lesson_card.dart';
import 'package:qvise/features/content/presentation/screens/create_lesson_screen.dart';
import 'package:qvise/features/content/presentation/screens/lesson_screen.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class CreateTab extends ConsumerStatefulWidget {
  const CreateTab({super.key});

  @override
  ConsumerState<CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends ConsumerState<CreateTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _handleRefresh() async {
    // Refresh all relevant providers
    ref.invalidate(unlockedLessonsProvider);
    ref.invalidate(subjectsNotifierProvider);
    await ref.read(unlockedLessonsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    final unlockedLessonsAsync = ref.watch(unlockedLessonsProvider);

    if (!isOnline) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create'),
          centerTitle: false,
        ),
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: unlockedLessonsAsync.when(
        data: (unlockedLessons) {
          if (unlockedLessons.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.edit,
              title: 'Start Creating',
              description: 'Create your first lesson and start building your knowledge base!',
              buttonText: 'Create Lesson',
              onButtonPressed: () => _navigateToCreateLesson(),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              slivers: [
                // Header section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.screenPaddingAll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Learning',
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Add content to your unlocked lessons',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Create new lesson button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToCreateLesson(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Lesson'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Unlocked lessons list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = unlockedLessons[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: UnlockedLessonCard(
                            lesson: lesson,
                            onTap: () => _navigateToLesson(lesson),
                            onLessonUpdated: () {
                              // Refresh the relevant providers when lesson is updated
                              _refreshAfterLessonUpdate(lesson);
                            },
                          ),
                        );
                      },
                      childCount: unlockedLessons.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading lessons...'),
        error: (error, stack) => _buildErrorView(error.toString()),
      ),
    );
  }

  Widget _buildErrorView(String message) {
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
              onPressed: () {
                ref.invalidate(unlockedLessonsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
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
    ref.invalidate(topicsNotifierProvider(subjectName: lesson.subjectName));
    ref.invalidate(lessonsNotifierProvider(subjectName: lesson.subjectName, topicName: lesson.topicName));
  }
}