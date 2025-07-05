// lib/core/shell and tabs/create_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/core/routes/route_names.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/content/presentation/widgets/unlocked_lesson_card.dart';
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
  @override
  bool get wantKeepAlive => true;

  Future<void> _handleRefresh() async {
    await ref.refresh(unlockedLessonsProvider.future);
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
            onButtonPressed: () => context.push(RouteNames.subjectSelection),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: AppSpacing.screenPaddingAll,
              itemCount: unlockedLessons.length,
              itemBuilder: (context, index) {
                final lesson = unlockedLessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: UnlockedLessonCard(
                    lesson: lesson,
                    onTap: () => context.push('${RouteNames.app}/lesson/${lesson.id}'),
                    onDelete: () => _showDeleteDialog(context, ref, lesson),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(RouteNames.subjectSelection),
            icon: const Icon(Icons.add),
            label: const Text('New Lesson'),
          ),
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
                style:
                    context.textTheme.titleMedium?.copyWith(color: AppColors.error),
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
                await ref
                    .read(lessonsNotifierProvider(
                            lesson.subjectName, lesson.topicName)
                        .notifier)
                    .deleteLesson(lesson.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Lesson and flashcards deleted successfully'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
}