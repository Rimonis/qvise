// lib/features/flashcards/shared/data/models/flashcard_model.dart

import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/sync_status.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/flashcard_tag.dart';

part 'flashcard_model.freezed.dart';
part 'flashcard_model.g.dart';

@freezed
class FlashcardModel with _$FlashcardModel {
  const factory FlashcardModel({
    required String id,
    required String lessonId,
    required String userId,
    required String frontContent,
    required String backContent,
    required FlashcardTag tag,
    List<String>? hints,
    required double difficulty,
    required double masteryLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastReviewedAt,
    required int reviewCount,
    required int correctCount,
    required bool isFavorite,
    required bool isActive,
    String? notes,
    required SyncStatus syncStatus,
  }) = _FlashcardModel;

  const FlashcardModel._();

  factory FlashcardModel.fromJson(Map<String, dynamic> json) => _$FlashcardModelFromJson(json);

  factory FlashcardModel.fromEntity(Flashcard entity) {
    return FlashcardModel(
      id: entity.id,
      lessonId: entity.lessonId,
      userId: entity.userId,
      frontContent: entity.frontContent,
      backContent: entity.backContent,
      tag: entity.tag,
      hints: entity.hints,
      difficulty: entity.difficulty,
      masteryLevel: entity.masteryLevel,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastReviewedAt: entity.lastReviewedAt,
      reviewCount: entity.reviewCount,
      correctCount: entity.correctCount,
      isFavorite: entity.isFavorite,
      isActive: entity.isActive,
      notes: entity.notes,
      syncStatus: entity.syncStatus,
    );
  }

  Flashcard toEntity() {
    return Flashcard(
      id: id,
      lessonId: lessonId,
      userId: userId,
      frontContent: frontContent,
      backContent: backContent,
      tag: tag,
      hints: hints,
      difficulty: difficulty,
      masteryLevel: masteryLevel,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastReviewedAt: lastReviewedAt,
      reviewCount: reviewCount,
      correctCount: correctCount,
      isFavorite: isFavorite,
      isActive: isActive,
      notes: notes,
      syncStatus: syncStatus,
    );
  }

  /// Convert to database format (SQLite)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'lessonId': lessonId,
      'userId': userId,
      'frontContent': frontContent,
      'backContent': backContent,
      'tag': jsonEncode(tag.toJson()),
      'hints': hints != null ? jsonEncode(hints) : null,
      'difficulty': difficulty,
      'masteryLevel': masteryLevel,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastReviewedAt': lastReviewedAt?.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'isFavorite': isFavorite ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'notes': notes,
      'syncStatus': syncStatus.name,
    };
  }

  /// Create from database format (SQLite)
  factory FlashcardModel.fromDatabase(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      lessonId: map['lessonId'] as String,
      userId: map['userId'] as String,
      frontContent: map['frontContent'] as String,
      backContent: map['backContent'] as String,
      tag: FlashcardTag.fromJson(jsonDecode(map['tag'] as String)),
      hints: map['hints'] != null 
          ? List<String>.from(jsonDecode(map['hints'] as String))
          : null,
      difficulty: map['difficulty'] as double,
      masteryLevel: map['masteryLevel'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      lastReviewedAt: map['lastReviewedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewedAt'] as int)
          : null,
      reviewCount: map['reviewCount'] as int,
      correctCount: map['correctCount'] as int,
      isFavorite: (map['isFavorite'] as int) == 1,
      isActive: (map['isActive'] as int) == 1,
      notes: map['notes'] as String?,
      syncStatus: SyncStatus.values.byName(map['syncStatus'] as String),
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'lessonId': lessonId,
      'userId': userId,
      'frontContent': frontContent,
      'backContent': backContent,
      'tag': tag.toJson(),
      'hints': hints,
      'difficulty': difficulty,
      'masteryLevel': masteryLevel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastReviewedAt': lastReviewedAt,
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'isFavorite': isFavorite,
      'isActive': isActive,
      'notes': notes,
      'syncStatus': syncStatus.name,
    };
  }

  /// Create from Firestore format
  factory FlashcardModel.fromFirestore(Map<String, dynamic> map, String id) {
    return FlashcardModel(
      id: id,
      lessonId: map['lessonId'] as String,
      userId: map['userId'] as String,
      frontContent: map['frontContent'] as String,
      backContent: map['backContent'] as String,
      tag: FlashcardTag.fromJson(map['tag'] as Map<String, dynamic>),
      hints: map['hints'] != null 
          ? List<String>.from(map['hints'] as List)
          : null,
      difficulty: (map['difficulty'] as num).toDouble(),
      masteryLevel: (map['masteryLevel'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastReviewedAt: map['lastReviewedAt'] != null 
          ? DateTime.parse(map['lastReviewedAt'] as String)
          : null,
      reviewCount: map['reviewCount'] as int,
      correctCount: map['correctCount'] as int,
      isFavorite: map['isFavorite'] as bool,
      isActive: map['isActive'] as bool,
      notes: map['notes'] as String?,
      syncStatus: SyncStatus.values.byName(map['syncStatus'] as String),
    );
  }

  /// Create a copy with sync status changed
  FlashcardModel markAsSynced() {
    return copyWith(
      syncStatus: SyncStatus.synced,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy marked as pending sync
  FlashcardModel markAsPending() {
    return copyWith(
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated review data
  FlashcardModel withReviewResult({
    required bool wasCorrect,
    required DateTime reviewedAt,
    double? newMasteryLevel,
  }) {
    return copyWith(
      lastReviewedAt: reviewedAt,
      reviewCount: reviewCount + 1,
      correctCount: wasCorrect ? correctCount + 1 : correctCount,
      masteryLevel: newMasteryLevel ?? masteryLevel,
      updatedAt: reviewedAt,
      syncStatus: SyncStatus.pending,
    );
  }

  /// Calculate accuracy percentage
  double get accuracy {
    if (reviewCount == 0) return 0.0;
    return correctCount / reviewCount;
  }

  /// Check if flashcard needs review (based on SRS algorithm)
  bool get needsReview {
    if (lastReviewedAt == null) return true;
    
    // Simple SRS calculation - in production, use more sophisticated algorithm
    final daysSinceReview = DateTime.now().difference(lastReviewedAt!).inDays;
    final intervalDays = (masteryLevel * 30).toInt().clamp(1, 365);
    
    return daysSinceReview >= intervalDays;
  }

  /// Get next review date
  DateTime get nextReviewDate {
    if (lastReviewedAt == null) return DateTime.now();
    
    final intervalDays = (masteryLevel * 30).toInt().clamp(1, 365);
    return lastReviewedAt!.add(Duration(days: intervalDays));
  }

  /// Check if this is a new flashcard (never reviewed)
  bool get isNew => reviewCount == 0;

  /// Check if this flashcard is mastered
  bool get isMastered => masteryLevel >= 0.8;

  /// Get difficulty level description
  String get difficultyDescription {
    if (difficulty < 0.3) return 'Easy';
    if (difficulty < 0.7) return 'Medium';
    return 'Hard';
  }

  /// Get mastery level description
  String get masteryDescription {
    if (masteryLevel < 0.2) return 'Novice';
    if (masteryLevel < 0.4) return 'Beginner';
    if (masteryLevel < 0.6) return 'Intermediate';
    if (masteryLevel < 0.8) return 'Advanced';
    return 'Mastered';
  }
}
