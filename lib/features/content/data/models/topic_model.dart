// lib/features/content/data/models/topic_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/topic.dart';

part 'topic_model.freezed.dart';
part 'topic_model.g.dart';

@freezed
class TopicModel with _$TopicModel {
  const factory TopicModel({
    required String name,
    required String subjectName,
    required String userId,
    required double proficiency,
    required int lessonCount,
    required DateTime lastStudied,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(1) int version,
  }) = _TopicModel;

  const TopicModel._();

  factory TopicModel.fromJson(Map<String, dynamic> json) => _$TopicModelFromJson(json);

  factory TopicModel.fromEntity(Topic topic) {
    return TopicModel(
      name: topic.name,
      subjectName: topic.subjectName,
      userId: topic.userId,
      proficiency: topic.proficiency,
      lessonCount: topic.lessonCount,
      lastStudied: topic.lastStudied,
      createdAt: topic.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Topic toEntity() {
    return Topic(
      name: name,
      subjectName: subjectName,
      userId: userId,
      proficiency: proficiency,
      lessonCount: lessonCount,
      lastStudied: lastStudied,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'name': name,
      'subjectName': subjectName,
      'userId': userId,
      'proficiency': proficiency,
      'lessonCount': lessonCount,
      'lastStudied': lastStudied.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'version': version,
    };
  }

  factory TopicModel.fromDatabase(Map<String, dynamic> map) {
    return TopicModel(
      name: map['name'] as String,
      subjectName: map['subjectName'] as String,
      userId: map['userId'] as String,
      proficiency: map['proficiency'] as double,
      lessonCount: map['lessonCount'] as int,
      lastStudied: DateTime.fromMillisecondsSinceEpoch(map['lastStudied'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int) : null,
      version: map['version'] as int? ?? 1,
    );
  }
}
