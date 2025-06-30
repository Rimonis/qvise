import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/entities/topic.dart';
import '../providers/content_state_providers.dart';
import '../widgets/topic_tile.dart';
import '../widgets/empty_content_widget.dart';
import '../widgets/content_loading_widget.dart';

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
      appBar: AppBar(
        title: Text(subjectName),
        centerTitle: true,
        bottom: selectedSubject != null
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
                ),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                onPressed: () => ref.invalidate(topicsNotifierProvider(subjectName)),
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
                extra: {'subjectName': subjectName},
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
            fontSize: 20,
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
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref, Topic topic) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${topic.name}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:\n'
              '• ${topic.lessonCount} lessons\n\n'
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
                          await ref.read(topicsNotifierProvider(subjectName).notifier).deleteTopic(topic.name);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${topic.name}" deleted successfully'),
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
}