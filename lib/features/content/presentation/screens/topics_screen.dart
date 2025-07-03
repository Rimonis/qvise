import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/entities/topic.dart';
import '../providers/content_state_providers.dart';
import '../widgets/topic_tile.dart';
import '../widgets/empty_content_widget.dart';
import '../widgets/content_loading_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class TopicsScreen extends ConsumerWidget {
  final String subjectName;
  
  const TopicsScreen({
    super.key,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName));
    final selectedSubject = ref.watch(selectedSubjectProvider);
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          subjectName,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        bottom: selectedSubject != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildStatsHeader(context, selectedSubject),
              )
            : null,
      ),
      body: topicsAsync.when(
        data: (topics) {
          if (topics.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.topic,
              title: 'No Topics Yet',
              description: 'Create a lesson in this subject to add topics!',
              buttonText: 'Create Lesson',
              onButtonPressed: isOnline
                  ? () => context.push(RouteNames.createLesson, extra: {'subjectName': subjectName})
                  : null,
              showOfflineMessage: !isOnline,
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => ref.read(topicsNotifierProvider(subjectName).notifier).refresh(),
            color: context.primaryColor,
            backgroundColor: context.surfaceColor,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return TopicTile(
                  topic: topic,
                  onTap: () {
                    ref.read(selectedTopicProvider.notifier).select(topic);
                    context.push('${RouteNames.subjects}/$subjectName/${topic.name}');
                  },
                  onDelete: isOnline ? () => _showDeleteDialog(context, ref, topic) : null,
                );
              },
            ),
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading topics...'),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
      floatingActionButton: isOnline ? _buildFloatingActionButton(context) : null,
    );
  }

  Widget _buildStatsHeader(BuildContext context, selectedSubject) {
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
            'Topics',
            selectedSubject.topicCount.toString(),
          ),
          _buildStatItem(
            context,
            'Lessons',
            selectedSubject.lessonCount.toString(),
          ),
          _buildStatItem(
            context,
            'Proficiency',
            '${(selectedSubject.proficiency * 100).toInt()}%',
            color: Color(int.parse(selectedSubject.proficiencyColor.replaceAll('#', '0xFF'))),
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
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? context.textPrimaryColor,
          ),
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
              onPressed: () => ref.invalidate(topicsNotifierProvider(subjectName)),
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
        extra: {'subjectName': subjectName},
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
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref, Topic topic) {
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
            Text(
              'This action cannot be undone.',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.errorColor,
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
                          await ref.read(topicsNotifierProvider(subjectName).notifier).deleteTopic(topic.name);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${topic.name}" deleted successfully'),
                                backgroundColor: context.successColor,
                                behavior: SnackBarBehavior.floating,
                                margin: AppSpacing.screenPaddingAll,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete: ${e.toString()}'),
                                backgroundColor: context.errorColor,
                                behavior: SnackBarBehavior.floating,
                                margin: AppSpacing.screenPaddingAll,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.errorColor,
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
}