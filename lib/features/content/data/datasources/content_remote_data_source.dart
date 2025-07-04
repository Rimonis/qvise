// lib/features/content/data/datasources/content_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

abstract class ContentRemoteDataSource {
  Future<LessonModel> createLesson(LessonModel lesson);
  Future<void> updateLesson(LessonModel lesson);
  Future<void> deleteLesson(String lessonId);
  Future<void> deleteLessonsByTopic(
      String userId, String subjectName, String topicName);
  Future<void> deleteLessonsBySubject(String userId, String subjectName);
  Future<List<LessonModel>> getUserLessons(String userId);
  Future<void> syncLessons(List<LessonModel> lessons);
  Future<void> lockLesson(String lessonId);
}

class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final FirebaseFirestore _firestore;

  ContentRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _lessonsCollection =>
      _firestore.collection('lessons');

  @override
  Future<LessonModel> createLesson(LessonModel lesson) async {
    try {
      final docRef = await _lessonsCollection.add(lesson.toFirestore());
      return lesson.copyWith(id: docRef.id, isSynced: true);
    } catch (e) {
      throw Exception('Failed to create lesson: $e');
    }
  }

  @override
  Future<void> updateLesson(LessonModel lesson) async {
    try {
      await _lessonsCollection.doc(lesson.id).update(lesson.toFirestore());
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _lessonsCollection.doc(lessonId).delete();
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }

  @override
  Future<void> deleteLessonsByTopic(
      String userId, String subjectName, String topicName) async {
    try {
      final querySnapshot = await _lessonsCollection
          .where('userId', isEqualTo: userId)
          .where('subjectName', isEqualTo: subjectName)
          .where('topicName', isEqualTo: topicName)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete lessons by topic: $e');
    }
  }

  @override
  Future<void> deleteLessonsBySubject(String userId, String subjectName) async {
    try {
      final querySnapshot = await _lessonsCollection
          .where('userId', isEqualTo: userId)
          .where('subjectName', isEqualTo: subjectName)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete lessons by subject: $e');
    }
  }

  @override
  Future<List<LessonModel>> getUserLessons(String userId) async {
    try {
      final querySnapshot = await _lessonsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              LessonModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user lessons: $e');
    }
  }

  @override
  Future<void> syncLessons(List<LessonModel> lessons) async {
    try {
      final batch = _firestore.batch();

      for (final lesson in lessons) {
        if (lesson.id.isEmpty) {
          final docRef = _lessonsCollection.doc();
          batch.set(docRef, lesson.toFirestore());
        } else {
          batch.update(
              _lessonsCollection.doc(lesson.id), lesson.toFirestore());
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to sync lessons: $e');
    }
  }

  @override
  Future<void> lockLesson(String lessonId) async {
    try {
      await _lessonsCollection.doc(lessonId).update({
        'isLocked': true,
        'lockedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to lock lesson: $e');
    }
  }
}
