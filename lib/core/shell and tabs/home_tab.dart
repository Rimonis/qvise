import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/content/presentation/widgets/content_loading_widget.dart';
import 'package:qvise/features/content/presentation/widgets/due_lesson_card.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';

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
        
        // Sort lessons by priority (due now first, then by next review date)
        final sortedLessons = [...dueLessons];
        sortedLessons.sort((a, b) {
          // Due lessons first
          if (a.isReviewDue && !b.isReviewDue) return -1;
          if (!a.isReviewDue && b.isReviewDue) return 1;
          
          // Then by next review date
          return a.nextReviewDate.compareTo(b.nextReviewDate);
        });
        
        return RefreshIndicator(
          onRefresh: () => ref.refresh(dueLessonsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedLessons.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header with stats
                return _buildHeader(context, sortedLessons);
              }
              
              final lesson = sortedLessons[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DueLessonCard(
                  lesson: lesson,
                  onTap: () {
                    // Navigate to lesson detail/study screen
                    // TODO: Implement lesson study screen navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Study "${lesson.displayTitle}" - Coming Soon'),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading lessons: ${error.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
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
    final dueNowCount = dueLessons.where((l) => l.isReviewDue).length;
    final dueTodayCount = dueLessons.where((l) => l.daysUntilReview == 0 && !l.isReviewDue).length;
    final dueSoonCount = dueLessons.length - dueNowCount - dueTodayCount;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Today\'s Review',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Due Now',
                  dueNowCount.toString(),
                  Colors.orange[300]!,
                  Icons.alarm,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Due Today',
                  dueTodayCount.toString(),
                  Colors.yellow[300]!,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Due Soon',
                  dueSoonCount.toString(),
                  Colors.blue[300]!,
                  Icons.upcoming,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}