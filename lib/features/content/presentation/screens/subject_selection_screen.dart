import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/content_state_providers.dart';
import '../widgets/content_loading_widget.dart';
import 'topic_selection_screen.dart';
import 'create_lesson_screen.dart';

class SubjectSelectionScreen extends ConsumerWidget {
  const SubjectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Subject'),
        centerTitle: true,
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length + 1, // +1 for "New Subject" tile
            itemBuilder: (context, index) {
              if (index == subjects.length) {
                // "New Subject" tile at the bottom
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
                      'New Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    subtitle: const Text('Create a lesson in a new subject'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.green,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateLessonScreen(),
                        ),
                      );
                    },
                  ),
                );
              }
              
              final subject = subjects[index];
              final proficiencyColor = Color(int.parse(subject.proficiencyColor.replaceAll('#', '0xFF')));
              
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
                      Icons.school,
                      color: proficiencyColor,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    subject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${subject.topicCount} topics • ${subject.lessonCount} lessons\n${subject.proficiencyLabel}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TopicSelectionScreen(
                          subjectName: subject.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading subjects...'),
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
                onPressed: () => ref.invalidate(subjectsNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}