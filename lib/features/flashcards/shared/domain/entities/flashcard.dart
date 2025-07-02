import 'package:freezed_annotation/freezed_annotation.dart';

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
    @Default(0.5) double difficulty, // 0.0 = easiest, 1.0 = hardest
    @Default(0.0) double masteryLevel, // 0.0 = not learned, 1.0 = mastered
    required DateTime createdAt,
    DateTime? lastReviewedAt,
    @Default(0) int reviewCount,
    @Default(0) int correctCount,
    @Default(false) bool isFavorite,
    @Default(true) bool isActive,
    String? notes, // Optional study notes
    List<String>? hints, // Optional hints for difficult cards
    @Default('pending') String syncStatus, // 'synced' | 'pending' | 'conflict'
  }) = _Flashcard;
  
  const Flashcard._();
  
  // Calculate success rate
  double get successRate {
    if (reviewCount == 0) return 0.0;
    return correctCount / reviewCount;
  }
  
  // Get visual difficulty indicator
  String get difficultyEmoji {
    if (difficulty < 0.33) return '🟢';
    if (difficulty < 0.67) return '🟡';
    return '🔴';
  }
  
  // Get mastery status
  FlashcardMasteryStatus get masteryStatus {
    if (masteryLevel >= 0.9) return FlashcardMasteryStatus.mastered;
    if (masteryLevel >= 0.7) return FlashcardMasteryStatus.proficient;
    if (masteryLevel >= 0.4) return FlashcardMasteryStatus.learning;
    if (masteryLevel > 0.0) return FlashcardMasteryStatus.struggling;
    return FlashcardMasteryStatus.new_;
  }
  
  // Check if card needs attention (low success rate)
  bool get needsAttention {
    return reviewCount >= 3 && successRate < 0.6;
  }
  
  // Get display title for UI
  String get displayTitle {
    if (frontContent.length <= 50) return frontContent;
    return '${frontContent.substring(0, 47)}...';
  }
  
  // Check if this is a new card
  bool get isNew => reviewCount == 0;
}

enum FlashcardMasteryStatus {
  new_,       // Never reviewed
  struggling, // Low success rate
  learning,   // Making progress
  proficient, // Good understanding
  mastered,   // Fully learned
}

// Simple flashcard creation parameters
@freezed
class CreateFlashcardParams with _$CreateFlashcardParams {
  const factory CreateFlashcardParams({
    required String lessonId,
    required String frontContent,
    required String backContent,
    required String tagId,
    double? difficulty,
    String? notes,
    List<String>? hints,
  }) = _CreateFlashcardParams;
}