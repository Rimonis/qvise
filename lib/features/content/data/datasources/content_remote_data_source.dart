// lib/features/content/data/datasources/content_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qvise/core/sync/utils/batch_helpers.dart';
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
  Future<void> deleteLessonsBySubject(
      String userId, String subjectName) async {
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
          .map((doc) => LessonModel.fromFirestore(doc.id, doc.data()))
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

  @override
  Future<List<LessonModel>> getLessonsByIds(List<String> ids) async {
    return BatchHelpers.batchProcess<String, LessonModel>(
      items: ids,
      processBatch: (batch) async {
        final snapshot = await _lessonsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        return snapshot.docs
            .map((doc) => LessonModel.fromFirestore(doc.id, doc.data()))
            .toList();
      },
    );
  }

  @override
  Future<List<LessonModel>> getLessonsModifiedSince(
      DateTime since, String userId) async {
    final snapshot = await _lessonsCollection
        .where('userId', isEqualTo: userId)
        .where('updated_at', isGreaterThan: Timestamp.fromDate(since))
        .get();
    return snapshot.docs
        .map((doc) => LessonModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> batchUpdateLessons(List<LessonModel> lessons) async {
    final batch = _firestore.batch();
    for (final lesson in lessons) {
      final docRef = _lessonsCollection.doc(lesson.id);
      batch.set(docRef, lesson.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<SubjectModel>> getSubjectsByIds(List<String> ids) async {
    return BatchHelpers.batchProcess<String, SubjectModel>(
        items: ids,
        processBatch: (batch) async {
          final snapshot = await _subjectsCollection
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          return snapshot.docs
              .map((doc) => SubjectModel.fromJson(doc.data()))
              .toList();
        });
  }

  @override
  Future<List<TopicModel>> getTopicsByIds(List<String> ids) async {
    return BatchHelpers.batchProcess<String, TopicModel>(
        items: ids,
        processBatch: (batch) async {
          final snapshot = await _topicsCollection
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          return snapshot.docs
              .map((doc) => TopicModel.fromJson(doc.data()))
              .toList();
        });
  }

  @override
  Future<void> batchUpdateSubjects(List<SubjectModel> subjects) async {
    final batch = _firestore.batch();
    for (final subject in subjects) {
      final docRef = _subjectsCollection.doc('${subject.userId}_${subject.name}');
      batch.set(docRef, subject.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<void> batchUpdateTopics(List<TopicModel> topics) async {
    final batch = _firestore.batch();
    for (final topic in topics) {
      final docRef = _topicsCollection
          .doc('${topic.userId}_${topic.subjectName}_${topic.name}');
      batch.set(docRef, topic.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<SubjectModel>> getSubjectsModifiedSince(
      DateTime since, String userId) async {
    final snapshot = await _subjectsCollection
        .where('userId', isEqualTo: userId)
        .where('updated_at', isGreaterThan: Timestamp.fromDate(since))
        .get();
    return snapshot.docs
        .map((doc) => SubjectModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<TopicModel>> getTopicsModifiedSince(
      DateTime since, String userId) async {
    final snapshot = await _topicsCollection
        .where('userId', isEqualTo: userId)
        .where('updated_at', isGreaterThan: Timestamp.fromDate(since))
        .get();
    return snapshot.docs
        .map((doc) => TopicModel.fromJson(doc.data()))
        .toList();
  }
}