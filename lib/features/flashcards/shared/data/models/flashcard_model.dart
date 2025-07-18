// lib/features/flashcards/shared/data/models/flashcard_model.dart

import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';

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
    @_FlashcardTagConverter() required FlashcardTag tag,
    @Default(0.5) double difficulty,
    @Default(0.0) double masteryLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastReviewedAt,
    @Default(0) int reviewCount,
    @Default(0) int correctCount,
    @Default(false) bool isFavorite,
    @Default(true) bool isActive,
    String? notes,
    List<String>? hints,
    @Default('pending') String syncStatus,
    @Default(1) int version,
  }) = _FlashcardModel;

  const FlashcardModel._();

  factory FlashcardModel.fromJson(Map<String, dynamic> json) =>
      _$FlashcardModelFromJson(json);

  factory FlashcardModel.fromEntity(Flashcard flashcard) {
    return FlashcardModel(
      id: flashcard.id,
      lessonId: flashcard.lessonId,
      userId: flashcard.userId,
      frontContent: flashcard.frontContent,
      backContent: flashcard.backContent,
      tag: flashcard.tag,
      difficulty: flashcard.difficulty,
      masteryLevel: flashcard.masteryLevel,
      createdAt: flashcard.createdAt,
      updatedAt: DateTime.now(),
      lastReviewedAt: flashcard.lastReviewedAt,
      reviewCount: flashcard.reviewCount,
      correctCount: flashcard.correctCount,
      isFavorite: flashcard.isFavorite,
      isActive: flashcard.isActive,
      notes: flashcard.notes,
      hints: flashcard.hints,
      syncStatus: flashcard.syncStatus,
      version: 1, // Version increment is handled in the repository
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
      difficulty: difficulty,
      masteryLevel: masteryLevel,
      createdAt: createdAt,
      lastReviewedAt: lastReviewedAt,
      reviewCount: reviewCount,
      correctCount: correctCount,
      isFavorite: isFavorite,
      isActive: isActive,
      notes: notes,
      hints: hints,
      syncStatus: syncStatus,
    );
  }

  // These methods are for sqflite which doesn't use the generator
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'front_content': frontContent,
      'back_content': backContent,
      'tag_id': tag.id,
      'tag_name': tag.name,
      'tag_emoji': tag.emoji,
      'tag_color': tag.color,
      'tag_category': tag.category?.toString().split('.').last ?? 'core',
      'difficulty': difficulty,
      'mastery_level': masteryLevel,
      'review_count': reviewCount,
      'correct_count': correctCount,
      'is_favorite': isFavorite ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'hints': hints != null ? jsonEncode(hints) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'version': version,
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      lessonId: map['lesson_id'] as String,
      frontContent: map['front_content'] as String,
      backContent: map['back_content'] as String,
      tag: FlashcardTag.systemTags.firstWhere(
          (t) => t.id == (map['tag_id'] as String),
          orElse: () => FlashcardTag.definition),
      difficulty: (map['difficulty'] as num?)?.toDouble() ?? 0.5,
      masteryLevel: (map['mastery_level'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['review_count'] as int?) ?? 0,
      correctCount: (map['correct_count'] as int?) ?? 0,
      isFavorite: (map['is_favorite'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      notes: map['notes'] as String?,
      hints: map['hints'] != null
          ? List<String>.from(jsonDecode(map['hints'] as String))
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastReviewedAt: map['last_reviewed_at'] != null
          ? DateTime.parse(map['last_reviewed_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      version: map['version'] as int? ?? 1,
    );
  }
}

// Custom JsonConverter for the FlashcardTag type
class _FlashcardTagConverter
    implements JsonConverter<FlashcardTag, Map<String, dynamic>> {
  const _FlashcardTagConverter();

  @override
  FlashcardTag fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? 'definition';
    return FlashcardTag.systemTags.firstWhere(
      (tag) => tag.id == id,
      orElse: () => FlashcardTag.definition,
    );
  }

  @override
  Map<String, dynamic> toJson(FlashcardTag tag) {
    return {
      'id': tag.id,
      'name': tag.name,
      'emoji': tag.emoji,
      'color': tag.color,
      'category': tag.category?.toString().split('.').last,
    };
  }
}