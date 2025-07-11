// lib/features/content/data/models/lesson_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lesson.dart';

part 'lesson_model.freezed.dart';
part 'lesson_model.g.dart';

@freezed
class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String userId,
    required String subjectName,
    required String topicName,
    String? title,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lockedAt,
    required DateTime nextReviewDate,
    DateTime? lastReviewedAt,
    required int reviewStage,
    required double proficiency,
    @Default(false) bool isLocked,
    @Default(0) int flashcardCount,
    @Default(0) int fileCount,
    @Default(0) int noteCount,
  }) = _LessonModel;

  const LessonModel._();

  factory LessonModel.fromJson(Map<String, dynamic> json) => _$LessonModelFromJson(json);

  factory LessonModel.fromEntity(Lesson lesson) {
    return LessonModel(
      id: lesson.id,
      userId: lesson.userId,
      subjectName: lesson.subjectName,
      topicName: lesson.topicName,
      title: lesson.title,
      createdAt: lesson.createdAt,
      updatedAt: lesson.updatedAt,
      lockedAt: lesson.lockedAt,
      nextReviewDate: lesson.nextReviewDate,
      lastReviewedAt: lesson.lastReviewedAt,
      reviewStage: lesson.reviewStage,
      proficiency: lesson.proficiency,
      isLocked: lesson.isLocked,
      flashcardCount: lesson.flashcardCount,
      fileCount: lesson.fileCount,
      noteCount: lesson.noteCount,
    );
  }

  Lesson toEntity() {
    return Lesson(
      id: id,
      userId: userId,
      subjectName: subjectName,
      topicName: topicName,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lockedAt: lockedAt,
      nextReviewDate: nextReviewDate,
      lastReviewedAt: lastReviewedAt,
      reviewStage: reviewStage,
      proficiency: proficiency,
      isLocked: isLocked,
      flashcardCount: flashcardCount,
      fileCount: fileCount,
      noteCount: noteCount,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'userId': userId,
      'subjectName': subjectName,
      'topicName': topicName,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lockedAt': lockedAt?.millisecondsSinceEpoch,
      'nextReviewDate': nextReviewDate.millisecondsSinceEpoch,
      'lastReviewedAt': lastReviewedAt?.millisecondsSinceEpoch,
      'reviewStage': reviewStage,
      'proficiency': proficiency,
      'isLocked': isLocked? 1 : 0,
      'flashcardCount': flashcardCount,
      'fileCount': fileCount,
      'noteCount': noteCount,
    };
  }

  factory LessonModel.fromDatabase(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      subjectName: map['subjectName'] as String,
      topicName: map['topicName'] as String,
      title: map['title'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      lockedAt: map['lockedAt']!= null? DateTime.fromMillisecondsSinceEpoch(map['lockedAt'] as int) : null,
      nextReviewDate: DateTime.fromMillisecondsSinceEpoch(map as int),
      lastReviewedAt: map!= null? DateTime.fromMillisecondsSinceEpoch(map as int) : null,
      reviewStage: map as int,
      proficiency: map['proficiency'] as double,
      isLocked: (map['isLocked'] as int) == 1,
      flashcardCount: map['flashcardCount'] as int,
      fileCount: map['fileCount'] as int,
      noteCount: map['noteCount'] as int,
    );
  }
}