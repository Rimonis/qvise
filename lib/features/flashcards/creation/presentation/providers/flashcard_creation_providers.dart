// lib/features/flashcards/creation/presentation/providers/flashcard_creation_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/providers.dart';
import '../../domain/usecases/create_flashcard.dart';
import '../../../shared/presentation/providers/flashcard_providers.dart';

// Provider for the create flashcard use case
final createFlashcardProvider = Provider<CreateFlashcard>((ref) {
  return CreateFlashcard(
    ref.watch(flashcardRepositoryProvider),
    ref.watch(firebaseAuthProvider),
  );
});