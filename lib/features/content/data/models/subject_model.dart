// lib/features/content/data/models/subject_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/subject.dart';

part 'subject_model.freezed.dart';
part 'subject_model.g.dart';

@freezed
class SubjectModel with _$SubjectModel {
  const factory SubjectModel({
    required String name,
    required String userId,
    required double proficiency,
    required int lessonCount,
    required int topicCount,
    required DateTime lastStudied,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(1) int version,
  }) = _SubjectModel;

  const SubjectModel._();

  factory SubjectModel.fromJson(Map<String, dynamic> json) => _$SubjectModelFromJson(json);

  factory SubjectModel.fromEntity(Subject subject) {
    return SubjectModel(
      name: subject.name,
      userId: subject.userId,
      proficiency: subject.proficiency,
      lessonCount: subject.lessonCount,
      topicCount: subject.topicCount,
      lastStudied: subject.lastStudied,
      createdAt: subject.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Subject toEntity() {
    return Subject(
      name: name,
      userId: userId,
      proficiency: proficiency,
      lessonCount: lessonCount,
      topicCount: topicCount,
      lastStudied: lastStudied,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'name': name,
      'userId': userId,
      'proficiency': proficiency,
      'lessonCount': lessonCount,
      'topicCount': topicCount,
      'lastStudied': lastStudied.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'version': version,
    };
  }

  factory SubjectModel.fromDatabase(Map<String, dynamic> map) {
    return SubjectModel(
      name: map['name'] as String,
      userId: map['userId'] as String,
      proficiency: map['proficiency'] as double,
      lessonCount: map['lessonCount'] as int,
      topicCount: map['topicCount'] as int,
      lastStudied: DateTime.fromMillisecondsSinceEpoch(map['lastStudied'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int) : null,
      version: map['version'] as int? ?? 1,
    );
  }
}
