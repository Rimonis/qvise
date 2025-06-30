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
    DateTime? lockedAt,
    required DateTime nextReviewDate,
    DateTime? lastReviewedAt,
    required int reviewStage,
    required double proficiency,
    @Default(false) bool isLocked,
    @Default(false) bool isSynced,
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
      lockedAt: lesson.lockedAt,
      nextReviewDate: lesson.nextReviewDate,
      lastReviewedAt: lesson.lastReviewedAt,
      reviewStage: lesson.reviewStage,
      proficiency: lesson.proficiency,
      isLocked: lesson.isLocked,
      isSynced: lesson.isSynced,
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
      lockedAt: lockedAt,
      nextReviewDate: nextReviewDate,
      lastReviewedAt: lastReviewedAt,
      reviewStage: reviewStage,
      proficiency: proficiency,
      isLocked: isLocked,
      isSynced: isSynced,
      flashcardCount: flashcardCount,
      fileCount: fileCount,
      noteCount: noteCount,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subjectName': subjectName,
      'topicName': topicName,
      if (title != null) 'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lockedAt != null) 'lockedAt': Timestamp.fromDate(lockedAt!),
      'nextReviewDate': Timestamp.fromDate(nextReviewDate),
      if (lastReviewedAt != null) 'lastReviewedAt': Timestamp.fromDate(lastReviewedAt!),
      'reviewStage': reviewStage,
      'proficiency': proficiency,
      'isLocked': isLocked,
      'flashcardCount': flashcardCount,
      'fileCount': fileCount,
      'noteCount': noteCount,
    };
  }

  factory LessonModel.fromFirestore(String id, Map<String, dynamic> map) {
    return LessonModel(
      id: id,
      userId: map['userId'] as String,
      subjectName: map['subjectName'] as String,
      topicName: map['topicName'] as String,
      title: map['title'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lockedAt: map['lockedAt'] != null 
          ? (map['lockedAt'] as Timestamp).toDate() 
          : null,
      nextReviewDate: (map['nextReviewDate'] as Timestamp).toDate(),
      lastReviewedAt: map['lastReviewedAt'] != null 
          ? (map['lastReviewedAt'] as Timestamp).toDate() 
          : null,
      reviewStage: map['reviewStage'] as int,
      proficiency: (map['proficiency'] as num).toDouble(),
      isLocked: map['isLocked'] as bool? ?? false,
      isSynced: true,
      flashcardCount: map['flashcardCount'] as int? ?? 0,
      fileCount: map['fileCount'] as int? ?? 0,
      noteCount: map['noteCount'] as int? ?? 0,
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
      'lockedAt': lockedAt?.millisecondsSinceEpoch,
      'nextReviewDate': nextReviewDate.millisecondsSinceEpoch,
      'lastReviewedAt': lastReviewedAt?.millisecondsSinceEpoch,
      'reviewStage': reviewStage,
      'proficiency': proficiency,
      'isLocked': isLocked ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
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
      lockedAt: map['lockedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lockedAt'] as int)
          : null,
      nextReviewDate: DateTime.fromMillisecondsSinceEpoch(map['nextReviewDate'] as int),
      lastReviewedAt: map['lastReviewedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewedAt'] as int)
          : null,
      reviewStage: map['reviewStage'] as int,
      proficiency: map['proficiency'] as double,
      isLocked: (map['isLocked'] as int) == 1,
      isSynced: (map['isSynced'] as int) == 1,
      flashcardCount: map['flashcardCount'] as int? ?? 0,
      fileCount: map['fileCount'] as int? ?? 0,
      noteCount: map['noteCount'] as int? ?? 0,
    );
  }
}