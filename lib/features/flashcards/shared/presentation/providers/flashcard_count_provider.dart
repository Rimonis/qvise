// lib/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'flashcard_providers.dart';

part 'flashcard_count_provider.g.dart';

// Provider for flashcard count by lesson ID
@riverpod
Future<int> flashcardCount(Ref ref, String lessonId) async {
  final repository = ref.watch(flashcardRepositoryProvider);
  final result = await repository.countFlashcardsByLesson(lessonId);
  return result.fold(
    (failure) => 0, // Return 0 on failure instead of throwing
    (count) => count,
  );
}