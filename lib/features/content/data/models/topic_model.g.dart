// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TopicModelImpl _$$TopicModelImplFromJson(Map<String, dynamic> json) =>
    _$TopicModelImpl(
      name: json['name'] as String,
      subjectName: json['subjectName'] as String,
      userId: json['userId'] as String,
      proficiency: (json['proficiency'] as num).toDouble(),
      lessonCount: (json['lessonCount'] as num).toInt(),
      lastStudied: DateTime.parse(json['lastStudied'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TopicModelImplToJson(_$TopicModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'subjectName': instance.subjectName,
      'userId': instance.userId,
      'proficiency': instance.proficiency,
      'lessonCount': instance.lessonCount,
      'lastStudied': instance.lastStudied.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
