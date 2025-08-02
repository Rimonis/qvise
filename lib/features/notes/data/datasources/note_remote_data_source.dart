// lib/features/notes/data/datasources/note_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<void> createNote(NoteModel note);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(String noteId);
  Future<NoteModel?> getNote(String noteId);
  Future<List<NoteModel>> getNotesByLesson(String lessonId);
  Future<List<NoteModel>> getNotesByUser(String userId);
  Future<void> batchUpsert(List<NoteModel> notes);
  Future<List<NoteModel>> getUpdatedSince(DateTime? lastSync);
  Future<List<NoteModel>> getNotesByIds(List<String> noteIds); // FIX: Added missing method
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String collection = 'notes';

  NoteRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createNote(NoteModel note) async {
    await firestore
        .collection(collection)
        .doc(note.id)
        .set(note.toJson());
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await firestore
        .collection(collection)
        .doc(note.id)
        .update(note.toJson());
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await firestore
        .collection(collection)
        .doc(noteId)
        .update({
      'is_deleted': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<NoteModel?> getNote(String noteId) async {
    final doc = await firestore
        .collection(collection)
        .doc(noteId)
        .get();

    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return NoteModel.fromJson(data);
  }

  @override
  Future<List<NoteModel>> getNotesByLesson(String lessonId) async {
    final querySnapshot = await firestore
        .collection(collection)
        .where('lessonId', isEqualTo: lessonId)
        .where('is_deleted', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => NoteModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<NoteModel>> getNotesByUser(String userId) async {
    final querySnapshot = await firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('is_deleted', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => NoteModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> batchUpsert(List<NoteModel> notes) async {
    final batch = firestore.batch();
    
    for (final note in notes) {
      final docRef = firestore.collection(collection).doc(note.id);
      batch.set(docRef, note.toJson(), SetOptions(merge: true));
    }
    
    await batch.commit();
  }

  @override
  Future<List<NoteModel>> getUpdatedSince(DateTime? lastSync) async {
    Query query = firestore.collection(collection);
    
    if (lastSync != null) {
      query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSync));
    }
    
    final querySnapshot = await query.get();
    
    return querySnapshot.docs
        .map((doc) => NoteModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // FIX: Added implementation for getNotesByIds
  @override
  Future<List<NoteModel>> getNotesByIds(List<String> noteIds) async {
    if (noteIds.isEmpty) return [];
    
    final List<NoteModel> notes = [];
    
    // Firestore has a limit of 10 for 'whereIn' queries, so we need to batch
    const batchSize = 10;
    for (int i = 0; i < noteIds.length; i += batchSize) {
      final batch = noteIds.skip(i).take(batchSize).toList();
      
      final querySnapshot = await firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      notes.addAll(
        querySnapshot.docs
            .map((doc) => NoteModel.fromJson(doc.data()))
            .toList()
      );
    }
    
    return notes;
  }
}