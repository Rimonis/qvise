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

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'lessonId': lessonId,
      'userId': userId,
      'frontContent': frontContent,
      'backContent': backContent,
      'tag': jsonEncode(tag.toJson()),
      'hints': hints!= null? jsonEncode(hints) : null,
      'difficulty': difficulty,
      'masteryLevel': masteryLevel,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastReviewedAt': lastReviewedAt?.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'isFavorite': isFavorite? 1 : 0,
      'isActive': isActive? 1 : 0,
      'notes': notes,
      'syncStatus': syncStatus.name,
    };
  }

  factory FlashcardModel.fromDatabase(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      lessonId: map['lessonId'] as String,
      userId: map['userId'] as String,
      frontContent: map['frontContent'] as String,
      backContent: map['backContent'] as String,
      tag: FlashcardTag.fromJson(jsonDecode(map['tag'] as String)),
      hints: map['hints']!= null? (jsonDecode(map['hints'] as String) as List).cast<String>() : null,
      difficulty: map['difficulty'] as double,
      masteryLevel: map['masteryLevel'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      lastReviewedAt: map!= null? DateTime.fromMillisecondsSinceEpoch(map as int) : null,
      reviewCount: map['reviewCount'] as int,
      correctCount: map['correctCount'] as int,
      isFavorite: (map['isFavorite'] as int) == 1,
      isActive: (map['isActive'] as int) == 1,
      notes: map['notes'] as String?,
      syncStatus: SyncStatus.values.byName(map as String),
    );
  }
}