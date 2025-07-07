// lib/features/content/presentation/screens/lessons_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/entities/lesson.dart';
import '../providers/content_state_providers.dart';
import '../widgets/lesson_card.dart';
import '../widgets/empty_content_widget.dart';
import '../widgets/content_loading_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class LessonsScreen extends ConsumerWidget {
  final String subjectName;
  final String topicName;
  
  const LessonsScreen({
    super.key,
    required this.subjectName,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName));
    final selectedTopic = ref.watch(selectedTopicProvider);
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          topicName,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        bottom: selectedTopic != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildStatsHeader(context, selectedTopic),
              )
            : null,
      ),
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.book,
              title: 'No Lessons Yet',
              description: 'Create your first lesson in this topic!',
              buttonText: 'Create Lesson',
              onButtonPressed: isOnline
                  ? () => context.push(
                      RouteNames.createLesson,
                      extra: {
                        'subjectName': subjectName,
                        'topicName': topicName,
                      },
                    )
                  : null,
              showOfflineMessage: !isOnline,
            );
          }
          
          final sortedLessons = [...lessons]
            ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
          
          return RefreshIndicator(
            onRefresh: () => ref.read(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName).notifier).refresh(),
            color: context.primaryColor,
            backgroundColor: context.surfaceColor,
            child: ListView.builder(
              padding: AppSpacing.screenPaddingAll,
              itemCount: sortedLessons.length,
              itemBuilder: (context, index) {
                final lesson = sortedLessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: LessonCard(
                    lesson: lesson,
                    onTap: () {
                      context.push('${RouteNames.lessonDetail}/${lesson.id}');
                    },
                    onDelete: isOnline ? () => _showDeleteDialog(context, ref, lesson) : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading lessons...'),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
      floatingActionButton: isOnline ? _buildFloatingActionButton(context) : null,
    );
  }

  Widget _buildStatsHeader(BuildContext context, selectedTopic) {
    return Container(
      padding: AppSpacing.paddingSymmetricMd,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: context.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            'Subject',
            subjectName,
          ),
          _buildStatItem(
            context,
            'Lessons',
            selectedTopic.lessonCount.toString(),
          ),
          _buildStatItem(
            context,
            'Proficiency',
            '${(selectedTopic.proficiency * 100).toInt()}%',
            color: Color(int.parse(selectedTopic.proficiencyColor.replaceAll('#', '0xFF'))),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? context.textPrimaryColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: context.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error: ${error.toString()}',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push(
        RouteNames.createLesson,
        extra: {
          'subjectName': subjectName,
          'topicName': topicName,
        },
      ),
      icon: const Icon(Icons.add),
      label: const Text('New Lesson'),
      backgroundColor: context.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref, Lesson lesson) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Type CONFIRM to delete:',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'CONFIRM',
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.textTertiaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  borderSide: BorderSide(color: context.primaryColor, width: 2),
                ),
                contentPadding: AppSpacing.paddingSymmetricSm,
                filled: true,
                fillColor: context.surfaceVariantColor.withValues(alpha: 0.5),
              ),
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondaryColor,
            ),
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
                          await ref.read(lessonsNotifierProvider(subjectName: subjectName, topicName: topicName).notifier)
                              .deleteLesson(lesson.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lesson deleted successfully'),
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
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.textDisabledColor.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                ),
                child: const Text('Delete'),
              );
            },
          ),
        ],
        actionsPadding: AppSpacing.paddingAllMd,
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}