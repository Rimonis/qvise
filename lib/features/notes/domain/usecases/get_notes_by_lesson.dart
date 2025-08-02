// lib/features/notes/domain/usecases/get_notes_by_lesson.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/app_failure.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotesByLesson {
  final NoteRepository repository;
  final firebase_auth.FirebaseAuth firebaseAuth;

  GetNotesByLesson(this.repository, this.firebaseAuth);

  Future<Either<AppFailure, List<Note>>> call(String lessonId) async {
    try {
      // Get current user
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw const AppFailure(
          type: FailureType.auth, 
          message: 'User not authenticated'
        );
      }

      // Get notes from repository
      final result = await repository.getNotesByLesson(lessonId);
      
      return result.map((notes) {
        // Filter by current user and sort by last modified (newest first)
        return notes
            .where((note) => note.userId == currentUserId)
            .toList()
          ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
      });
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