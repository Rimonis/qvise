// lib/features/flashcards/creation/domain/usecases/create_flashcard.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/failures.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import '../entities/flashcard_difficulty.dart';

class CreateFlashcard {
  final FlashcardRepository repository;
  final firebase_auth.FirebaseAuth firebaseAuth;

  CreateFlashcard(this.repository, this.firebaseAuth);

  Future<Either<Failure, Flashcard>> call({
    required String lessonId,
    required String frontContent,
    required String backContent,
    required String tagId,
    required FlashcardDifficulty difficulty,
    String? notes,
    List<String>? hints,
  }) async {
    // Validation
    if (frontContent.trim().isEmpty) {
      return const Left(CacheFailure('Front content cannot be empty'));
    }
    
    if (backContent.trim().isEmpty) {
      return const Left(CacheFailure('Back content cannot be empty'));
    }

    try {
      // Get current user
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      // Get the tag
      final tag = _getSystemTag(tagId);
      if (tag == null) {
        return const Left(CacheFailure('Invalid tag selected'));
      }

      // Create flashcard entity
      final flashcard = Flashcard(
        id: _generateId(),
        lessonId: lessonId,
        userId: currentUserId,
        frontContent: frontContent.trim(),
        backContent: backContent.trim(),
        tag: tag,
        difficulty: difficulty.value,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        hints: hints?.where((h) => h.trim().isNotEmpty).map((h) => h.trim()).toList(),
        createdAt: DateTime.now(),
      );

      // Save to repository
      return await repository.createFlashcard(flashcard);
    } catch (e) {
      return Left(CacheFailure('Failed to create flashcard: ${e.toString()}'));
    }
  }

  String _generateId() => 'flashcard_${DateTime.now().millisecondsSinceEpoch}';
  
  String? _getCurrentUserId() {
    return firebaseAuth.currentUser?.uid;
  }
  
  FlashcardTag? _getSystemTag(String tagId) {
    try {
      return FlashcardTag.systemTags.firstWhere((tag) => tag.id == tagId);
    } catch (e) {
      return null;
    }
  }
}