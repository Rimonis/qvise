// lib/features/flashcards/presentation/screens/flashcard_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/widgets/error_display_widget.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/widgets/flashcard_preview_widget.dart';

class FlashcardPreviewScreen extends ConsumerWidget {
  final Lesson lesson;

  const FlashcardPreviewScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsByLessonProvider(lesson.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.displayTitle),
        actions:,
      ),
      body: flashcardsAsync.when(
        data: (flashcards) {
          if (flashcards.isEmpty) {
            return EmptyContentWidget(
              icon: Icons.style,
              title: 'No Flashcards Yet',
              description: 'Create your first flashcard for this lesson.',
              buttonText: 'Create Flashcard',
              onButtonPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FlashcardCreationScreen(
                      lessonId: lesson.id,
                      subjectName: lesson.subjectName,
                      topicName: lesson.topicName,
                    ),
                  ),
                );
              },
            );
          }
          return PageView.builder(
            itemCount: flashcards.length,
            itemBuilder: (context, index) {
              final flashcard = flashcards[index];
              return FlashcardPreviewWidget(
                frontContent: flashcard.frontContent,
                backContent: flashcard.backContent,
                tag: flashcard.tag,
                hints: flashcard.hints??,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final appError = error as AppError;
          return ErrorDisplayWidget(
            errorMessage: appError.userFriendlyMessage,
            onRetry: () => ref.invalidate(flashcardsByLessonProvider(lesson.id)),
          );
        },
      ),
    );
  }
}
