// lib/features/notes/domain/usecases/delete_note.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/note_repository.dart';

class DeleteNote {
  final NoteRepository repository;
  final firebase_auth.FirebaseAuth firebaseAuth;

  DeleteNote(this.repository, this.firebaseAuth);

  Future<Either<AppFailure, void>> call(String noteId) async {
    try {
      // Get current user
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw const AppFailure(
          type: FailureType.auth, 
          message: 'User not authenticated'
        );
      }

      // Get existing note to verify ownership
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
          message: 'Not authorized to delete this note'
        );
      }

      // Delete from repository
      return await repository.deleteNote(noteId);
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