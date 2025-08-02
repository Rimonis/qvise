// lib/features/notes/presentation/providers/note_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/data/providers/data_providers.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/note_local_data_source.dart';
import '../../data/datasources/note_remote_data_source.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/create_note.dart';
import '../../domain/usecases/update_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_notes_by_lesson.dart';

part 'note_providers.g.dart';

// --- Data Sources ---
@riverpod
NoteRemoteDataSource noteRemoteDataSource(Ref ref) {
  return NoteRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
}

// --- Repository ---
@riverpod
NoteRepository noteRepository(Ref ref) {
  return NoteRepositoryImpl(
    localDataSource: ref.watch(noteLocalDataSourceProvider),
    remoteDataSource: ref.watch(noteRemoteDataSourceProvider),
  );
}

// --- Use Cases ---
@riverpod
CreateNote createNote(Ref ref) {
  return CreateNote(
    ref.watch(noteRepositoryProvider),
    ref.watch(firebaseAuthProvider),
  );
}

@riverpod
UpdateNote updateNote(Ref ref) {
  return UpdateNote(
    ref.watch(noteRepositoryProvider),
    ref.watch(firebaseAuthProvider),
  );
}

@riverpod
DeleteNote deleteNote(Ref ref) {
  return DeleteNote(
    ref.watch(noteRepositoryProvider),
    ref.watch(firebaseAuthProvider),
  );
}

@riverpod
GetNotesByLesson getNotesByLesson(Ref ref) {
  return GetNotesByLesson(
    ref.watch(noteRepositoryProvider),
    ref.watch(firebaseAuthProvider),
  );
}

// --- State Providers ---
@riverpod
Future<List<Note>> lessonNotes(Ref ref, String lessonId) async {
  final useCase = ref.watch(getNotesByLessonProvider);
  final result = await useCase(lessonId);
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (notes) => notes,
  );
}

@riverpod
Future<int> noteCount(Ref ref, String lessonId) async {
  final repository = ref.watch(noteRepositoryProvider);
  final result = await repository.getNoteCount(lessonId);
  
  return result.fold(
    (failure) => 0,
    (noteCount) => noteCount,
  );
}