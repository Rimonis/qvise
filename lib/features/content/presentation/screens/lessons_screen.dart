import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/entities/lesson.dart';
import '../providers/content_state_providers.dart';
import '../widgets/lesson_card.dart';
import '../widgets/empty_content_widget.dart';
import '../widgets/content_loading_widget.dart';

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
    final lessonsAsync = ref.watch(lessonsNotifierProvider(subjectName, topicName));
    final selectedTopic = ref.watch(selectedTopicProvider);
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(topicName),
        centerTitle: true,
        bottom: selectedTopic != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
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
                ),
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
          
          // Sort lessons by review date
          final sortedLessons = [...lessons]
            ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
          
          return RefreshIndicator(
            onRefresh: () => ref.read(lessonsNotifierProvider(subjectName, topicName).notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedLessons.length,
              itemBuilder: (context, index) {
                final lesson = sortedLessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LessonCard(
                    lesson: lesson,
                    onTap: () {
                      // Navigate to lesson detail/study screen
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
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(lessonsNotifierProvider(subjectName, topicName)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isOnline
          ? FloatingActionButton.extended(
              onPressed: () => context.push(
                RouteNames.createLesson,
                extra: {
                  'subjectName': subjectName,
                  'topicName': topicName,
                },
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Lesson'),
            )
          : null,
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref, Lesson lesson) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${lesson.displayTitle}\n'
              'Created: ${_formatDate(lesson.createdAt)}\n'
              'Proficiency: ${(lesson.proficiency * 100).toInt()}%\n\n'
              'This action cannot be undone.',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type CONFIRM to delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'CONFIRM',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
                          await ref.read(lessonsNotifierProvider(subjectName, topicName).notifier)
                              .deleteLesson(lesson.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lesson deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              );
            },
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}