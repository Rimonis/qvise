// lib/features/flashcards/shared/domain/entities/flashcard.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'flashcard_tag.dart';
import 'sync_status.dart';

part 'flashcard.freezed.dart';

@freezed
class Flashcard with _$Flashcard {
  const factory Flashcard({
    required String id,
    required String lessonId,
    required String userId,
    required String frontContent,
    required String backContent,
    required FlashcardTag tag,
    List<String>? hints,
    @Default(0.5) double difficulty,
    @Default(0.0) double masteryLevel,
    required DateTime createdAt,
    required DateTime updatedAt, // Added for sync conflict resolution
    DateTime? lastReviewedAt,
    @Default(0) int reviewCount,
    @Default(0) int correctCount,
    @Default(false) bool isFavorite,
    @Default(true) bool isActive,
    String? notes,
    @Default(SyncStatus.pending) SyncStatus syncStatus, // Changed to enum
  }) = _Flashcard;

  const Flashcard._();

  double get successRate {
    if (reviewCount == 0) return 0.0;
    return correctCount / reviewCount;
  }

  FlashcardMasteryStatus get masteryStatus {
    if (masteryLevel >= 0.9) return FlashcardMasteryStatus.mastered;
    if (masteryLevel >= 0.7) return FlashcardMasteryStatus.proficient;
    if (masteryLevel >= 0.4) return FlashcardMasteryStatus.learning;
    if (masteryLevel > 0.0) return FlashcardMasteryStatus.struggling;
    return FlashcardMasteryStatus.new_;
  }

  bool get needsAttention {
    return (reviewCount > 5 && successRate < 0.6) |

| masteryStatus == FlashcardMasteryStatus.struggling;
  }
}

enum FlashcardMasteryStatus {
  new_,
  struggling,
  learning,
  proficient,
  mastered,
}