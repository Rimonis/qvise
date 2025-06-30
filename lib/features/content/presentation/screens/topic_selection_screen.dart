import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/content_state_providers.dart';
import '../widgets/content_loading_widget.dart';
import 'create_lesson_screen.dart';

class TopicSelectionScreen extends ConsumerWidget {
  final String subjectName;
  
  const TopicSelectionScreen({
    super.key,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsNotifierProvider(subjectName));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        centerTitle: true,
      ),
      body: topicsAsync.when(
        data: (topics) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length + 1, // +1 for "New Topic" tile
            itemBuilder: (context, index) {
              if (index == topics.length) {
                // "New Topic" tile at the bottom
                return Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'New Topic',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    subtitle: const Text('Create a lesson in a new topic'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.green,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateLessonScreen(
                            initialSubjectName: subjectName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              
              final topic = topics[index];
              final proficiencyColor = Color(int.parse(topic.proficiencyColor.replaceAll('#', '0xFF')));
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: proficiencyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.topic,
                      color: proficiencyColor,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    topic.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${topic.lessonCount} lessons • ${topic.proficiencyLabel}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateLessonScreen(
                          initialSubjectName: subjectName,
                          initialTopicName: topic.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
    );
  }
}