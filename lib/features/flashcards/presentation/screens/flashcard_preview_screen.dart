// lib/features/flashcards/presentation/screens/flashcard_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/presentation/widgets/empty_content_widget.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/flashcards/creation/presentation/widgets/flashcard_preview_widget.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/features/flashcards/creation/domain/entities/flashcard_difficulty.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class FlashcardPreviewScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final bool allowEditing;

  const FlashcardPreviewScreen({
    super.key,
    required this.lessonId,
    this.allowEditing = false,
  });

  @override
  ConsumerState<FlashcardPreviewScreen> createState() =>
      _FlashcardPreviewScreenState();
}

class _FlashcardPreviewScreenState extends ConsumerState<FlashcardPreviewScreen> {
  int _currentIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _navigateToCreateScreen(
      BuildContext context, WidgetRef ref, String subjectName, String topicName) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: widget.lessonId,
          subjectName: subjectName,
          topicName: topicName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
      }
    });
  }

  void _navigateToEditScreen(BuildContext context, WidgetRef ref, Lesson lesson, Flashcard flashcard) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardCreationScreen(
          lessonId: widget.lessonId,
          subjectName: lesson.subjectName,
          topicName: lesson.topicName,
          flashcardToEdit: flashcard,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
      }
    });
  }

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
          if (widget.allowEditing)
            flashcardsAsync.when(
              data: (flashcards) {
                if (flashcards.isEmpty || _currentIndex >= flashcards.length) {
                  return const SizedBox.shrink();
                }
                final flashcard = flashcards[_currentIndex];
                return lessonAsync.when(
                  data: (lesson) => lesson != null ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _navigateToEditScreen(context, ref, lesson, flashcard),
                        tooltip: 'Edit Flashcard',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, ref, flashcard),
                        tooltip: 'Delete Flashcard',
                      ),
                    ],
                  ) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
            return lessonAsync.when(
              data: (lesson) {
                if (lesson == null) return const Center(child: Text('Lesson not found.'));
                return EmptyContentWidget(
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'No Flashcards Yet',
                  description: 'Create the first flashcard for this lesson.',
                  buttonText: 'Create Flashcard',
                  onButtonPressed: widget.allowEditing ? () => _navigateToCreateScreen(
                    context,
                    ref,
                    lesson.subjectName,
                    lesson.topicName,
                  ) : null,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading lesson details: $e')),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
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
                    isFavorite: flashcard.isFavorite,
                    onToggleFavorite: () async {
                      await ref
                          .read(flashcardRepositoryProvider)
                          .toggleFavorite(flashcard.id);
                      ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
                    },
                  );
                },
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${flashcards.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (flashcards.length > 1)
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).size.height / 2 - 40,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          size: 20,
                          color: _currentIndex > 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: _currentIndex < flashcards.length - 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: widget.allowEditing ? lessonAsync.when(
        data: (lesson) => lesson != null
            ? FloatingActionButton.extended(
                onPressed: () => _navigateToCreateScreen(
                  context,
                  ref,
                  lesson.subjectName,
                  lesson.topicName,
                ),
                label: const Text('New Flashcard'),
                icon: const Icon(Icons.add),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ) : null,
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Flashcard?'),
        content: Text(
          'Are you sure you want to permanently delete this flashcard?',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(flashcardRepositoryProvider).deleteFlashcard(flashcard.id);
              ref.invalidate(flashcardsByLessonProvider(widget.lessonId));
              ref.invalidate(unlockedLessonsProvider);
              ref.invalidate(flashcardCountProvider(widget.lessonId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}