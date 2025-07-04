// lib/features/flashcards/presentation/screens/flashcard_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/widgets/flashcard_preview_widget.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/flashcards/creation/domain/entities/flashcard_difficulty.dart';

class FlashcardPreviewScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const FlashcardPreviewScreen({super.key, required this.lessonId});

  @override
  ConsumerState<FlashcardPreviewScreen> createState() =>
      _FlashcardPreviewScreenState();
}

class _FlashcardPreviewScreenState extends ConsumerState<FlashcardPreviewScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));
    final flashcardsAsync =
        ref.watch(flashcardsByLessonProvider(widget.lessonId));

    return Scaffold(
      appBar: AppBar(
        title: lessonAsync.when(
          data: (lesson) => Text('Preview: ${lesson?.displayTitle ?? '...'}'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          flashcardsAsync.when(
            data: (flashcards) {
              if (flashcards.isEmpty) return const SizedBox.shrink();
              final flashcard = flashcards[_currentIndex];
              return IconButton(
                icon: Icon(
                  flashcard.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: flashcard.isFavorite ? Colors.red : null,
                ),
                onPressed: () async {
                  await ref
                      .read(flashcardRepositoryProvider)
                      .toggleFavorite(flashcard.id);
                  ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
        ],
      ),
      body: flashcardsAsync.when(
        data: (flashcards) {
          if (flashcards.isEmpty) {
            return const Center(child: Text('No flashcards to preview.'));
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: flashcards.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final flashcard = flashcards[index];
                    return FlashcardPreviewWidget(
                      frontContent: flashcard.frontContent,
                      backContent: flashcard.backContent,
                      tag: flashcard.tag,
                      difficulty:
                          FlashcardDifficulty.fromValue(flashcard.difficulty),
                      hints: flashcard.hints ?? [],
                      notes: flashcard.notes,
                    );
                  },
                ),
              ),
              Padding(
                padding: AppSpacing.paddingAllMd,
                child: Text('${_currentIndex + 1} / ${flashcards.length}'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}