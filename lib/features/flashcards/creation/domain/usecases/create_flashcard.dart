// lib/features/flashcards/creation/domain/usecases/create_flashcard.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import 'package:uuid/uuid.dart';
import '../entities/flashcard_difficulty.dart';

class CreateFlashcard {
  final FlashcardRepository repository;
  final firebase_auth.FirebaseAuth firebaseAuth;
  final Uuid _uuid;

  CreateFlashcard(this.repository, this.firebaseAuth, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  Future<Either<AppFailure, Flashcard>> call({
    required String lessonId,
    required String frontContent,
    required String backContent,
    required String tagId,
    required FlashcardDifficulty difficulty,
    String? notes,
    List<String>? hints,
  }) async {
    try {
      // Validation
      if (frontContent.trim().isEmpty) {
        throw AppFailure(type: FailureType.validation, message: 'Front content cannot be empty');
      }
      
      if (backContent.trim().isEmpty) {
        throw AppFailure(type: FailureType.validation, message: 'Back content cannot be empty');
      }

      // Get current user
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw AppFailure(type: FailureType.auth, message: 'User not authenticated');
      }

      // Get the tag
      final tag = _getSystemTag(tagId);
      if (tag == null) {
        throw AppFailure(type: FailureType.validation, message: 'Invalid tag selected');
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
    } on AppFailure catch (e) {
      return Left(e);
    } catch (e, s) {
      return Left(AppFailure.fromException(e, s));
    }
  }

  String _generateId() => _uuid.v4();
  
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
