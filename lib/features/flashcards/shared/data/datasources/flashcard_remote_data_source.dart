// lib/features/flashcards/shared/data/datasources/flashcard_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flashcard_model.dart';

abstract class FlashcardRemoteDataSource {
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard);
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard);
  Future<void> deleteFlashcard(String id);
  Future<void> deleteFlashcardsByLesson(String lessonId);
  Future<FlashcardModel?> getFlashcard(String id);
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId);
  Future<List<FlashcardModel>> getFlashcardsByUser(String userId,
      {DateTime? since});
  Future<void> syncFlashcards(List<FlashcardModel> flashcards);
  Future<void> toggleFavorite(String flashcardId, bool isFavorite);
}

class FlashcardRemoteDataSourceImpl implements FlashcardRemoteDataSource {
  final FirebaseFirestore firestore;

  FlashcardRemoteDataSourceImpl({required this.firestore});

  @override
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard) async {
    final docRef = firestore.collection('flashcards').doc(flashcard.id);
    await docRef.set(flashcard.toJson());
    return flashcard.copyWith(syncStatus: 'synced');
  }

  @override
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard) async {
    final docRef = firestore.collection('flashcards').doc(flashcard.id);
    final updatedModel = flashcard.copyWith(
        updatedAt: DateTime.now(), syncStatus: 'synced');
    await docRef.update(updatedModel.toJson());
    return updatedModel;
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    await firestore.collection('flashcards').doc(id).delete();
  }

  @override
  Future<void> deleteFlashcardsByLesson(String lessonId) async {
    final querySnapshot = await firestore
        .collection('flashcards')
        .where('lessonId', isEqualTo: lessonId)
        .get();
    final batch = firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<FlashcardModel?> getFlashcard(String id) async {
    final doc = await firestore.collection('flashcards').doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return FlashcardModel.fromJson(doc.data()!);
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId) async {
    final querySnapshot = await firestore
        .collection('flashcards')
        .where('lessonId', isEqualTo: lessonId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => FlashcardModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByUser(String userId,
      {DateTime? since}) async {
    Query query = firestore
        .collection('flashcards')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true);
    if (since != null) {
      query = query.where('updatedAt', isGreaterThan: since.toIso8601String());
    }
    final querySnapshot =
        await query.orderBy('updatedAt', descending: true).get();
    return querySnapshot.docs
        .map((doc) => FlashcardModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> syncFlashcards(List<FlashcardModel> flashcards) async {
    final batch = firestore.batch();
    for (final flashcard in flashcards) {
      final docRef = firestore.collection('flashcards').doc(flashcard.id);
      batch.set(docRef, flashcard.copyWith(syncStatus: 'synced').toJson());
    }
    await batch.commit();
  }

  @override
  Future<void> toggleFavorite(String flashcardId, bool isFavorite) async {
    await firestore
        .collection('flashcards')
        .doc(flashcardId)
        .update({'isFavorite': isFavorite});
  }
}
