// lib/features/notes/data/repositories/note_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/data/repositories/base_repository.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_data_source.dart';
import '../datasources/note_remote_data_source.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl extends BaseRepository implements NoteRepository {
  final NoteLocalDataSource localDataSource;
  final NoteRemoteDataSource remoteDataSource;

  NoteRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<AppFailure, Note>> createNote(Note note) async {
    return guard(() async {
      final noteModel = NoteModel.fromEntity(note);
      
      // Save locally first
      await localDataSource.insertNote(noteModel);
      
      // Try to sync to remote
      try {
        await remoteDataSource.createNote(noteModel);
        
        // Mark as synced if remote save succeeds
        await localDataSource.markAsSynced(note.id);
        
        return note.copyWith(syncStatus: 'synced');
      } catch (e) {
        // Return note even if remote sync fails - it's saved locally
        return note;
      }
    });
  }

  @override
  Future<Either<AppFailure, Note>> updateNote(Note note) async {
    return guard(() async {
      final noteModel = NoteModel.fromEntity(note);
      
      // Update locally first
      await localDataSource.updateNote(noteModel);
      
      // Try to sync to remote
      try {
        await remoteDataSource.updateNote(noteModel);
        
        // Mark as synced if remote update succeeds
        await localDataSource.markAsSynced(note.id);
        
        return note.copyWith(syncStatus: 'synced');
      } catch (e) {
        // Return updated note even if remote sync fails
        return note;
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteNote(String noteId) async {
    return guard(() async {
      // Delete locally (soft delete)
      await localDataSource.deleteNote(noteId);
      
      // Try to sync to remote
      try {
        await remoteDataSource.deleteNote(noteId);
      } catch (e) {
        // Continue even if remote delete fails - it's marked for deletion locally
      }
    });
  }

  @override
  Future<Either<AppFailure, Note?>> getNote(String noteId) async {
    return guard(() async {
      final noteModel = await localDataSource.getNote(noteId);
      return noteModel?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Note>>> getNotesByLesson(String lessonId) async {
    return guard(() async {
      final noteModels = await localDataSource.getNotesByLesson(lessonId);
      return noteModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Note>>> getAllNotes(String userId) async {
    return guard(() async {
      final noteModels = await localDataSource.getAllNotes(userId);
      return noteModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, int>> getNoteCount(String lessonId) async {
    return guard(() async {
      return await localDataSource.getNoteCount(lessonId);
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteNotesByLesson(String lessonId) async {
    return guard(() async {
      // Delete all notes for this lesson (cascading delete functionality)
      await localDataSource.deleteNotesByLesson(lessonId);
      
      // Remote cleanup will be handled by sync service
    });
  }
}