// lib/core/shell_and_tabs/create_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/core/routes/route_names.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_error_handler.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/screens/lesson_screen.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/content/presentation/widgets/unlocked_lesson_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CreateTab extends ConsumerStatefulWidget {
  const CreateTab({super.key});

  @override
  ConsumerState<CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends ConsumerState<CreateTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ## FIX: 'await' is added ##
  Future<void> _handleRefresh() async {
    await ref.refresh(unlockedLessonsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ## FIX: Removed the call to .handleError() ##
    final unlockedLessonsAsync = ref.watch(unlockedLessonsProvider);
    final isOnline = ref.watch(networkStatusProvider).asData?.value ?? false;

    return VisibilityDetector(
      key: const Key('create_tab_visibility_detector'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1.0) {
          ref.invalidate(unlockedLessonsProvider);
        }
      },
      child: isOnline
          ? unlockedLessonsAsync.when(
              data: (unlockedLessons) {
                if (unlockedLessons.isEmpty) {
                  return EmptyContentWidget(
                    icon: Icons.edit_note_sharp,
                    title: 'Start Creating',
                    description:
                        'Create your first lesson and start building your knowledge base!',
                    buttonText: 'Create Lesson',
                    onButtonPressed: () =>
                        context.push(RouteNames.subjectSelection),
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
                            // OPTION 1: Using GoRouter (cleaner and more consistent)
                            onTap: () {
                              context.push('${RouteNames.app}/lesson/${lesson.id}').then((_) {
                                // Refresh the create tab when returning
                                ref.invalidate(unlockedLessonsProvider);
                              });
                            },
                            onDelete: isOnline
                                ? () => _showDeleteDialog(context, ref, lesson)
                                : null,
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
              loading: () =>
                  const ContentLoadingWidget(message: 'Loading lessons...'),
              error: (error, stack) => _buildErrorView(
                message: _getErrorMessage(error),
                onRetry: () => ref.invalidate(unlockedLessonsProvider),
              ),
            )
          : _buildOfflineWidget(),
    );
  }

  Widget _buildOfflineWidget() {
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

  Widget _buildErrorView(
      {required String message, required VoidCallback onRetry}) {
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Lesson lesson) {
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
              child: Text(
                'Lesson: ${lesson.displayTitle}',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
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
                await ref
                    .read(lessonsNotifierProvider(
                            subjectName: lesson.subjectName,
                            topicName: lesson.topicName)
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

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
