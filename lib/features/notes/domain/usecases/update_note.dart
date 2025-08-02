// lib/features/notes/domain/usecases/update_note.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/app_failure.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class UpdateNote {
  final NoteRepository repository;
  final firebase_auth.FirebaseAuth firebaseAuth;

  UpdateNote(this.repository, this.firebaseAuth);

  Future<Either<AppFailure, Note>> call({
    required String noteId,
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

      // Get existing note
      final noteResult = await repository.getNote(noteId);
      final existingNote = noteResult.fold(
        (failure) => throw failure,
        (note) => note,
      );

      if (existingNote == null) {
        throw const AppFailure(
          type: FailureType.notFound, 
          message: 'Note not found'
        );
      }

      // Verify ownership
      if (existingNote.userId != currentUserId) {
        throw const AppFailure(
          type: FailureType.auth, 
          message: 'Not authorized to update this note'
        );
      }

      // Create updated note
      final updatedNote = existingNote.copyWith(
        title: title?.trim().isEmpty == true ? null : title?.trim(),
        content: content.trim(),
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      // Save to repository
      return await repository.updateNote(updatedNote);
    } on AppFailure catch (e) {
      return Left(e);
    } catch (e, s) {
      return Left(AppFailure.fromException(e, s));
    }
  }

  String? _getCurrentUserId() {
    return firebaseAuth.currentUser?.uid;
  }
}