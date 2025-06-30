import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';

@freezed
class Subject with _$Subject {
  const factory Subject({
    required String name,
    required String userId,
    required double proficiency,
    required int lessonCount,
    required int topicCount,
    required DateTime lastStudied,
    required DateTime createdAt,
  }) = _Subject;
  
  const Subject._();
  
  // Calculate color based on proficiency
  String get proficiencyColor {
    if (proficiency >= 0.8) return '#4CAF50'; // Green
    if (proficiency >= 0.6) return '#FFC107'; // Amber
    if (proficiency >= 0.4) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }
  
  String get proficiencyLabel {
    if (proficiency >= 0.8) return 'Excellent';
    if (proficiency >= 0.6) return 'Good';
    if (proficiency >= 0.4) return 'Fair';
    return 'Needs Practice';
  }
}