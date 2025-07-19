// lib/features/files/presentation/screens/lesson_files_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/files/presentation/widgets/file_list_widget.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class LessonFilesScreen extends ConsumerWidget {
  final String lessonId;

  const LessonFilesScreen({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonProvider(lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Files')),
            body: const Center(child: Text('Lesson not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Files'),
                Text(
                  lesson.displayTitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          body: FileListWidget(lessonId: lessonId),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Files')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Files')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text('Error: $error'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.refresh(lessonProvider(lessonId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}