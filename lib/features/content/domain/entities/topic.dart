import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic.freezed.dart';

@freezed
class Topic with _$Topic {
  const factory Topic({
    required String name,
    required String subjectName,
    required String userId,
    required double proficiency,
    required int lessonCount,
    required DateTime lastStudied,
    required DateTime createdAt,
  }) = _Topic;
  
  const Topic._();
  
  // Calculate color based on proficiency
  String get proficiencyColor {
    if (proficiency >= 0.8) return '#4CAF50'; // Green
    if (proficiency >= 0.6) return '#FFC107'; // Amber
    if (proficiency >= 0.4) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }
  
  String get proficiencyLabel {
    if (proficiency >= 0.8) return 'Mastered';
    if (proficiency >= 0.6) return 'Proficient';
    if (proficiency >= 0.4) return 'Learning';
    return 'Beginning';
  }
}