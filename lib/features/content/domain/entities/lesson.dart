// lib/features/content/domain/entities/lesson.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson.freezed.dart';

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required String id,
    required String userId,
    required String subjectName,
    required String topicName,
    String? title,
    required DateTime createdAt,
    required DateTime updatedAt, // Added for sync conflict resolution
    DateTime? lockedAt,
    required DateTime nextReviewDate,
    DateTime? lastReviewedAt,
    required int reviewStage,
    required double proficiency,
    @Default(false) bool isLocked,
    @Default(0) int flashcardCount,
    @Default(0) int fileCount,
    @Default(0) int noteCount,
  }) = _Lesson;

  const Lesson._();

  String get displayTitle {
    if (title!= null && title!.isNotEmpty) {
      return title!;
    }
    final months =;
    final month = months[createdAt.month - 1];
    final day = createdAt.day;
    final year = createdAt.year;
    return '$month $day, $year';
  }

  bool get isReviewDue {
    if (!isLocked) return false;
    return DateTime.now().isAfter(nextReviewDate);
  }

  int get daysUntilReview {
    if (!isLocked) return 0;
    final difference = nextReviewDate.difference(DateTime.now());
    return difference.inDays;
  }

  String get reviewStatus {
    if (!isLocked) return 'Unlocked';
    if (isReviewDue) return 'Due Now';
    if (daysUntilReview == 0) return 'Due Today';
    if (daysUntilReview == 1) return 'Due Tomorrow';
    return 'Due in $daysUntilReview days';
  }

  String get proficiencyColor {
    if (proficiency >= 0.8) return '#4CAF50'; // Green
    if (proficiency >= 0.6) return '#FFC107'; // Amber
    if (proficiency >= 0.4) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }
}