// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LessonModelImpl _$$LessonModelImplFromJson(Map<String, dynamic> json) =>
    _$LessonModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subjectName: json['subjectName'] as String,
      topicName: json['topicName'] as String,
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lockedAt:
          json['lockedAt'] == null
              ? null
              : DateTime.parse(json['lockedAt'] as String),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      lastReviewedAt:
          json['lastReviewedAt'] == null
              ? null
              : DateTime.parse(json['lastReviewedAt'] as String),
      reviewStage: (json['reviewStage'] as num).toInt(),
      proficiency: (json['proficiency'] as num).toDouble(),
      isLocked: json['isLocked'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? false,
      flashcardCount: (json['flashcardCount'] as num?)?.toInt() ?? 0,
      fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
      noteCount: (json['noteCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$LessonModelImplToJson(_$LessonModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'subjectName': instance.subjectName,
      'topicName': instance.topicName,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'lockedAt': instance.lockedAt?.toIso8601String(),
      'nextReviewDate': instance.nextReviewDate.toIso8601String(),
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
      'reviewStage': instance.reviewStage,
      'proficiency': instance.proficiency,
      'isLocked': instance.isLocked,
      'isSynced': instance.isSynced,
      'flashcardCount': instance.flashcardCount,
      'fileCount': instance.fileCount,
      'noteCount': instance.noteCount,
    };
