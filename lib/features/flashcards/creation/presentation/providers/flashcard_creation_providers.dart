import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/create_flashcard.dart';
import '../../../shared/presentation/providers/flashcard_providers.dart';

// Provider for the create flashcard use case
final createFlashcardProvider = Provider<CreateFlashcard>((ref) {
  return CreateFlashcard(ref.watch(flashcardRepositoryProvider));
});