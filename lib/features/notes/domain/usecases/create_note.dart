// lib/features/notes/domain/usecases/create_note.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/app_failure.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class CreateNote {
  final NoteRepository repository;
  final firebase_auth.FirebaseAuth firebaseAuth;

  CreateNote(this.repository, this.firebaseAuth);

  Future<Either<AppFailure, Note>> call({
    required String lessonId,
    String? title,
    required String content,
  }) async {
    try {
      // Validation
      if (content.trim().isEmpty) {
        throw const AppFailure(
          type: FailureType.validation, 
          message: 'Note content cannot be empty'
        );
      }

      // Get current user
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw const AppFailure(
          type: FailureType.auth, 
          message: 'User not authenticated'
        );
      }

      // Create note entity
      final note = Note(
        id: _generateId(),
        lessonId: lessonId,
        userId: currentUserId,
        title: title?.trim().isEmpty == true ? null : title?.trim(),
        content: content.trim(),
        createdAt: DateTime.now(),
      );

      // Save to repository
      return await repository.createNote(note);
    } on AppFailure catch (e) {
      return Left(e);
    } catch (e, s) {
      return Left(AppFailure.fromException(e, s));
    }
  }

  String _generateId() => 'note_${DateTime.now().millisecondsSinceEpoch}';
  
  String? _getCurrentUserId() {
    return firebaseAuth.currentUser?.uid;
  }
}