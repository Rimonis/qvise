// lib/features/flashcards/shared/data/datasources/flashcard_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flashcard_model.dart';

abstract class FlashcardRemoteDataSource {
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard);
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard);
  Future<void> deleteFlashcard(String id);
  Future<FlashcardModel?> getFlashcard(String id);
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId);
  Future<List<FlashcardModel>> getFlashcardsByUser(String userId, {DateTime? since});
  Future<void> syncFlashcards(List<FlashcardModel> flashcards);
}

class FlashcardRemoteDataSourceImpl implements FlashcardRemoteDataSource {
  final FirebaseFirestore firestore;

  FlashcardRemoteDataSourceImpl({required this.firestore});

  @override
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard) async {
    try {
      final docRef = firestore.collection('flashcards').doc(flashcard.id);
      
      await docRef.set({
        'id': flashcard.id,
        'userId': flashcard.userId,
        'lessonId': flashcard.lessonId,
        'frontContent': flashcard.frontContent,
        'backContent': flashcard.backContent,
        'tag': {
          'id': flashcard.tag.id,
          'name': flashcard.tag.name,
          'emoji': flashcard.tag.emoji,
          'color': flashcard.tag.color,
          'category': flashcard.tag.category?.toString().split('.').last,
        },
        'difficulty': flashcard.difficulty,
        'masteryLevel': flashcard.masteryLevel,
        'reviewCount': flashcard.reviewCount,
        'correctCount': flashcard.correctCount,
        'isFavorite': flashcard.isFavorite,
        'isActive': flashcard.isActive,
        'notes': flashcard.notes,
        'hints': flashcard.hints,
        'createdAt': flashcard.createdAt.toIso8601String(),
        'updatedAt': flashcard.updatedAt.toIso8601String(),
        'lastReviewedAt': flashcard.lastReviewedAt?.toIso8601String(),
        'syncStatus': 'synced',
      });

      return flashcard.copyWith(syncStatus: 'synced');
    } catch (e) {
      throw Exception('Failed to create flashcard: ${e.toString()}');
    }
  }

  @override
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard) async {
    try {
      final docRef = firestore.collection('flashcards').doc(flashcard.id);
      
      await docRef.update({
        'frontContent': flashcard.frontContent,
        'backContent': flashcard.backContent,
        'tag': {
          'id': flashcard.tag.id,
          'name': flashcard.tag.name,
          'emoji': flashcard.tag.emoji,
          'color': flashcard.tag.color,
          'category': flashcard.tag.category?.toString().split('.').last,
        },
        'difficulty': flashcard.difficulty,
        'masteryLevel': flashcard.masteryLevel,
        'reviewCount': flashcard.reviewCount,
        'correctCount': flashcard.correctCount,
        'isFavorite': flashcard.isFavorite,
        'isActive': flashcard.isActive,
        'notes': flashcard.notes,
        'hints': flashcard.hints,
        'updatedAt': DateTime.now().toIso8601String(),
        'lastReviewedAt': flashcard.lastReviewedAt?.toIso8601String(),
        'syncStatus': 'synced',
      });

      return flashcard.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'synced',
      );
    } catch (e) {
      throw Exception('Failed to update flashcard: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    try {
      await firestore.collection('flashcards').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete flashcard: ${e.toString()}');
    }
  }

  @override
  Future<FlashcardModel?> getFlashcard(String id) async {
    try {
      final doc = await firestore.collection('flashcards').doc(id).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return FlashcardModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get flashcard: ${e.toString()}');
    }
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId) async {
    try {
      final querySnapshot = await firestore
          .collection('flashcards')
          .where('lessonId', isEqualTo: lessonId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get flashcards by lesson: ${e.toString()}');
    }
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByUser(
    String userId, {
    DateTime? since,
  }) async {
    try {
      Query query = firestore
          .collection('flashcards')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true);

      if (since != null) {
        query = query.where('updatedAt', isGreaterThan: since.toIso8601String());
      }

      final querySnapshot = await query
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get flashcards by user: ${e.toString()}');
    }
  }

  @override
  Future<void> syncFlashcards(List<FlashcardModel> flashcards) async {
    try {
      final batch = firestore.batch();

      for (final flashcard in flashcards) {
        final docRef = firestore.collection('flashcards').doc(flashcard.id);
        
        batch.set(docRef, {
          'id': flashcard.id,
          'userId': flashcard.userId,
          'lessonId': flashcard.lessonId,
          'frontContent': flashcard.frontContent,
          'backContent': flashcard.backContent,
          'tag': {
            'id': flashcard.tag.id,
            'name': flashcard.tag.name,
            'emoji': flashcard.tag.emoji,
            'color': flashcard.tag.color,
            'category': flashcard.tag.category?.toString().split('.').last,
          },
          'difficulty': flashcard.difficulty,
          'masteryLevel': flashcard.masteryLevel,
          'reviewCount': flashcard.reviewCount,
          'correctCount': flashcard.correctCount,
          'isFavorite': flashcard.isFavorite,
          'isActive': flashcard.isActive,
          'notes': flashcard.notes,
          'hints': flashcard.hints,
          'createdAt': flashcard.createdAt.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'lastReviewedAt': flashcard.lastReviewedAt?.toIso8601String(),
          'syncStatus': 'synced',
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to sync flashcards: ${e.toString()}');
    }
  }
}