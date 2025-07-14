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
  }) = _Lesson;

  const Lesson._();

  // Business logic methods
  bool get isDue => DateTime.now().isAfter(nextReviewDate) && !isLocked;
  
  bool get needsReview => isDue;
  
  bool get hasContent => flashcardCount > 0 || fileCount > 0 || noteCount > 0;
  
  double get completionPercentage => proficiency.clamp(0.0, 1.0);
  
  String get proficiencyLevel {
    if (proficiency >= 0.8) return 'Expert';
    if (proficiency >= 0.6) return 'Advanced';
    if (proficiency >= 0.4) return 'Intermediate';
    if (proficiency >= 0.2) return 'Beginner';
    return 'Novice';
  }
  
  Duration get timeSinceLastReview {
    if (lastReviewedAt == null) return Duration.zero;
    return DateTime.now().difference(lastReviewedAt!);
  }

  Duration get timeUntilNextReview {
    final now = DateTime.now();
    if (now.isAfter(nextReviewDate)) return Duration.zero;
    return nextReviewDate.difference(now);
  }

  // Copy methods for state updates
  Lesson markAsReviewed({
    required double newProficiency,
    required DateTime nextReview,
    required int newReviewStage,
  }) {
    return copyWith(
      proficiency: newProficiency,
      nextReviewDate: nextReview,
      reviewStage: newReviewStage,
      lastReviewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Lesson lock() {
    return copyWith(
      isLocked: true,
      lockedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Lesson unlock() {
    return copyWith(
      isLocked: false,
      lockedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  Lesson updateContentCounts({
    int? flashcardCount,
    int? fileCount,
    int? noteCount,
  }) {
    return copyWith(
      flashcardCount: flashcardCount ?? this.flashcardCount,
      fileCount: fileCount ?? this.fileCount,
      noteCount: noteCount ?? this.noteCount,
      updatedAt: DateTime.now(),
    );
  }
}

