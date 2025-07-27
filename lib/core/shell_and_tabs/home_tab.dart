// lib/core/shell and tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/due_lesson_card.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
// Theme imports
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueLessonsAsync = ref.watch(dueLessonsProvider);
    
    return dueLessonsAsync.when(
      data: (dueLessons) {
        if (dueLessons.isEmpty) {
          return const EmptyContentWidget(
            icon: Icons.celebration,
            title: 'All Caught Up!',
            description: 'No lessons are due for review today.\nGreat job staying on top of your studies!',
          );
        }
        
        final sortedLessons = [...dueLessons];
        sortedLessons.sort((a, b) {
          if (a.isReviewDue && !b.isReviewDue) return -1;
          if (!a.isReviewDue && b.isReviewDue) return 1;
          return a.nextReviewDate.compareTo(b.nextReviewDate);
        });
        
        return RefreshIndicator(
          onRefresh: () => ref.refresh(dueLessonsProvider.future),
          child: ListView.builder(
            padding: AppSpacing.screenPaddingAll,
            itemCount: sortedLessons.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHeader(context, sortedLessons);
              }
              
              final lesson = sortedLessons[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: DueLessonCard(
                  lesson: lesson,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Study "${lesson.displayTitle}" - Coming Soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const ContentLoadingWidget(message: 'Loading due lessons...'),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading lessons',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(dueLessonsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, List<Lesson> dueLessons) {
    // Unchanged...
    final dueNowCount = dueLessons.where((l) => l.isReviewDue).length;
    final dueTodayCount = dueLessons.where((l) => l.daysUntilReview == 0 && !l.isReviewDue).length;
    final dueSoonCount = dueLessons.length - dueNowCount - dueTodayCount;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: AppSpacing.paddingAllLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor,
            context.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.today,
                color: Colors.white,
                size: AppSpacing.iconLg,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Today\'s Review',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Due Now',
                  dueNowCount.toString(),
                  AppColors.accent,
                  Icons.alarm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Due Today',
                  dueTodayCount.toString(),
                  AppColors.warning,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Due Soon',
                  dueSoonCount.toString(),
                  AppColors.info,
                  Icons.upcoming,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String label, 
    String value, 
    Color color, 
    IconData icon
  ) {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: AppSpacing.iconLg,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
