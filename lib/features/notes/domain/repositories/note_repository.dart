// lib/features/notes/domain/repositories/note_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<Either<AppFailure, Note>> createNote(Note note);
  Future<Either<AppFailure, Note>> updateNote(Note note);
  Future<Either<AppFailure, void>> deleteNote(String noteId);
  Future<Either<AppFailure, Note?>> getNote(String noteId);
  Future<Either<AppFailure, List<Note>>> getNotesByLesson(String lessonId);
  Future<Either<AppFailure, List<Note>>> getAllNotes(String userId);
  Future<Either<AppFailure, int>> getNoteCount(String lessonId);
  Future<Either<AppFailure, void>> deleteNotesByLesson(String lessonId);
}