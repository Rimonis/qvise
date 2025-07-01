import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/entities/subject.dart';
import '../providers/content_state_providers.dart';
import '../widgets/subject_card.dart';
import '../widgets/empty_content_widget.dart';
import '../widgets/content_loading_widget.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsNotifierProvider);
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.push(RouteNames.profile);
            },
          ),
        ],
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.school,
              title: 'No Subjects Yet',
              description: 'Create your first lesson to get started!',
              buttonText: 'Create Lesson',
              onButtonPressed: isOnline
                  ? () => context.push(RouteNames.createLesson)
                  : null,
              showOfflineMessage: !isOnline,
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => ref.read(subjectsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SubjectCard(
                    subject: subject,
                    onTap: () {
                      ref.read(selectedSubjectProvider.notifier).select(subject);
                      context.push('${RouteNames.subjects}/${subject.name}');
                    },
                    onDelete: isOnline ? () => _showDeleteDialog(context, ref, subject) : null,
                  ),
                );
              },
            ),
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
      floatingActionButton: isOnline
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RouteNames.createLesson),
              icon: const Icon(Icons.add),
              label: const Text('New Lesson'),
            )
          : null,
    );
  }
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref, Subject subject) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${subject.name}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:\n'
              '• ${subject.topicCount} topics\n'
              '• ${subject.lessonCount} lessons\n\n'
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
                          await ref.read(subjectsNotifierProvider.notifier).deleteSubject(subject.name);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${subject.name}" deleted successfully'),
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