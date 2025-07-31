// lib/features/content/data/datasources/content_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lesson_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';

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

  // New methods for sync service
  Future<List<LessonModel>> getLessonsByIds(List<String> ids);
  Future<List<LessonModel>> getLessonsModifiedSince(
      DateTime since, String userId);
  Future<void> batchUpdateLessons(List<LessonModel> lessons);
  Future<List<SubjectModel>> getSubjectsByIds(List<String> ids);
  Future<List<TopicModel>> getTopicsByIds(List<String> ids);
  Future<void> batchUpdateSubjects(List<SubjectModel> subjects);
  Future<void> batchUpdateTopics(List<TopicModel> topics);
  Future<List<SubjectModel>> getSubjectsModifiedSince(
      DateTime since, String userId);
  Future<List<TopicModel>> getTopicsModifiedSince(
      DateTime since, String userId);
}

class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final FirebaseFirestore _firestore;

  ContentRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _lessonsCollection =>
      _firestore.collection('lessons');
  CollectionReference<Map<String, dynamic>> get _subjectsCollection =>
      _firestore.collection('subjects');
  CollectionReference<Map<String, dynamic>> get _topicsCollection =>
      _firestore.collection('topics');

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
      // Delete lesson document
      await _lessonsCollection.doc(lessonId).delete();
      
      // Note: Files are handled by the file remote data source
      // This keeps the separation of concerns clean
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

      // Extract lesson IDs for file cleanup
      final lessonIds = querySnapshot.docs.map((doc) => doc.id).toList();

      // Delete lesson documents
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete associated files (in chunks to avoid Firestore limits)
      await _deleteFilesByLessonIds(lessonIds, userId);
    } catch (e) {
      throw Exception('Failed to delete lessons by topic: $e');
    }
  }

  @override
  Future<void> deleteLessonsBySubject(
      String userId, String subjectName) async {
    try {
      final querySnapshot = await _lessonsCollection
          .where('userId', isEqualTo: userId)
          .where('subjectName', isEqualTo: subjectName)
          .get();

      // Extract lesson IDs for file cleanup
      final lessonIds = querySnapshot.docs.map((doc) => doc.id).toList();

      // Delete lesson documents
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete associated files (in chunks to avoid Firestore limits)
      await _deleteFilesByLessonIds(lessonIds, userId);
    } catch (e) {
      throw Exception('Failed to delete lessons by subject: $e');
    }
  }

  /// Helper method to delete files for multiple lessons
  Future<void> _deleteFilesByLessonIds(List<String> lessonIds, String userId) async {
    if (lessonIds.isEmpty) return;
    
    try {
      // Process in chunks to avoid Firestore query limits
      const chunkSize = 10; // Firestore 'in' query limit
      
      for (int i = 0; i < lessonIds.length; i += chunkSize) {
        final chunk = lessonIds.skip(i).take(chunkSize).toList();
        
        final querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('files')
            .where('lesson_id', whereIn: chunk)
            .get();

        // Delete each file (both metadata and storage)
        final batch = _firestore.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
          
          // For mock, we don't delete from storage
          // Real implementation would delete from Firebase Storage here
          /* Real implementation (uncomment when firebase_storage is added):
          try {
            final fileId = doc.id;
            final storageRef = _storage.ref('users/$userId/files/$fileId');
            await storageRef.delete();
          } catch (e) {
            // File might not exist in storage, which is fine
            print('Could not delete file from storage: $e');
          }
          */
        }
        
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Non-critical failure: Could not delete remote files for lessons: $e');
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
          .map((doc) => LessonModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user lessons: $e');
    }
  }

  @override
  Future<void> syncLessons(List<LessonModel> lessons) async {
    try {
      const batchSize = 500; // Firestore batch limit
      for (int i = 0; i < lessons.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = lessons.skip(i).take(batchSize);
        
        for (final lesson in chunk) {
          final docRef = _lessonsCollection.doc(lesson.id);
          batch.set(docRef, lesson.toFirestore(), SetOptions(merge: true));
        }
        
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to sync lessons: $e');
    }
  }

  @override
  Future<void> lockLesson(String lessonId) async {
    try {
      await _lessonsCollection.doc(lessonId).update({
        'isLocked': true,
        'lockedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to lock lesson: $e');
    }
  }

  @override
  Future<List<LessonModel>> getLessonsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      // Process in chunks to avoid Firestore query limits
      const chunkSize = 10;
      final results = <LessonModel>[];
      
      for (int i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.skip(i).take(chunkSize).toList();
        final querySnapshot = await _lessonsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        results.addAll(querySnapshot.docs
            .map((doc) => LessonModel.fromFirestore(doc.id, doc.data())));
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to get lessons by IDs: $e');
    }
  }

  @override
  Future<List<LessonModel>> getLessonsModifiedSince(
      DateTime since, String userId) async {
    try {
      final querySnapshot = await _lessonsCollection
          .where('userId', isEqualTo: userId)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
          .get();

      return querySnapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get lessons modified since: $e');
    }
  }

  @override
  Future<void> batchUpdateLessons(List<LessonModel> lessons) async {
    try {
      const batchSize = 500; // Firestore batch limit
      for (int i = 0; i < lessons.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = lessons.skip(i).take(batchSize);
        
        for (final lesson in chunk) {
          final docRef = _lessonsCollection.doc(lesson.id);
          batch.set(docRef, lesson.toFirestore(), SetOptions(merge: true));
        }
        
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to batch update lessons: $e');
    }
  }

  @override
  Future<List<SubjectModel>> getSubjectsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      const chunkSize = 10;
      final results = <SubjectModel>[];
      
      for (int i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.skip(i).take(chunkSize).toList();
        final querySnapshot = await _subjectsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        results.addAll(querySnapshot.docs
            .map((doc) => SubjectModel.fromJson(doc.data())));
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to get subjects by IDs: $e');
    }
  }

  @override
  Future<List<TopicModel>> getTopicsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      const chunkSize = 10;
      final results = <TopicModel>[];
      
      for (int i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.skip(i).take(chunkSize).toList();
        final querySnapshot = await _topicsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        results.addAll(querySnapshot.docs
            .map((doc) => TopicModel.fromJson(doc.data())));
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to get topics by IDs: $e');
    }
  }

  @override
  Future<void> batchUpdateSubjects(List<SubjectModel> subjects) async {
    try {
      const batchSize = 500;
      for (int i = 0; i < subjects.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = subjects.skip(i).take(batchSize);
        
        for (final subject in chunk) {
          final docRef = _subjectsCollection.doc('${subject.userId}_${subject.name}');
          batch.set(docRef, subject.toJson(), SetOptions(merge: true));
        }
        
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to batch update subjects: $e');
    }
  }

  @override
  Future<void> batchUpdateTopics(List<TopicModel> topics) async {
    try {
      const batchSize = 500;
      for (int i = 0; i < topics.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = topics.skip(i).take(batchSize);
        
        for (final topic in chunk) {
          final docRef = _topicsCollection.doc('${topic.userId}_${topic.subjectName}_${topic.name}');
          batch.set(docRef, topic.toJson(), SetOptions(merge: true));
        }
        
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to batch update topics: $e');
    }
  }

  @override
  Future<List<SubjectModel>> getSubjectsModifiedSince(
      DateTime since, String userId) async {
    try {
      final querySnapshot = await _subjectsCollection
          .where('userId', isEqualTo: userId)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
          .get();

      return querySnapshot.docs
          .map((doc) => SubjectModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get subjects modified since: $e');
    }
  }

  @override
  Future<List<TopicModel>> getTopicsModifiedSince(
      DateTime since, String userId) async {
    try {
      final querySnapshot = await _topicsCollection
          .where('userId', isEqualTo: userId)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
          .get();

      return querySnapshot.docs
          .map((doc) => TopicModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get topics modified since: $e');
    }
  }
}