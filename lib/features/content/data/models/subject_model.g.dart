// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubjectModelImpl _$$SubjectModelImplFromJson(Map<String, dynamic> json) =>
    _$SubjectModelImpl(
      name: json['name'] as String,
      userId: json['userId'] as String,
      proficiency: (json['proficiency'] as num).toDouble(),
      lessonCount: (json['lessonCount'] as num).toInt(),
      topicCount: (json['topicCount'] as num).toInt(),
      lastStudied: DateTime.parse(json['lastStudied'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$SubjectModelImplToJson(_$SubjectModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'userId': instance.userId,
      'proficiency': instance.proficiency,
      'lessonCount': instance.lessonCount,
      'topicCount': instance.topicCount,
      'lastStudied': instance.lastStudied.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
