// lib/features/flashcards/shared/data/models/flashcard_model.dart

import 'dart:convert';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/flashcard_tag.dart';

class FlashcardModel {
  final String id;
  final String lessonId;
  final String userId;
  final String frontContent;
  final String backContent;
  final FlashcardTag tag;
  final double difficulty;
  final double masteryLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final int correctCount;
  final bool isFavorite;
  final bool isActive;
  final String? notes;
  final List<String>? hints;
  final String syncStatus;

  const FlashcardModel({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.frontContent,
    required this.backContent,
    required this.tag,
    this.difficulty = 0.5,
    this.masteryLevel = 0.0,
    required this.createdAt,
    DateTime? updatedAt,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.isFavorite = false,
    this.isActive = true,
    this.notes,
    this.hints,
    this.syncStatus = 'pending',
  }) : updatedAt = updatedAt ?? createdAt;

  // Convert to Map for SQLite
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
    };
  }

  // Create from SQLite Map
  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      lessonId: map['lesson_id'] as String,
      frontContent: map['front_content'] as String,
      backContent: map['back_content'] as String,
      tag: FlashcardTag(
        id: map['tag_id'] as String,
        name: map['tag_name'] as String,
        emoji: map['tag_emoji'] as String,
        color: map['tag_color'] as String,
        description: '', // Will be filled from system tags
        category: _parseTagCategory(map['tag_category'] as String?),
      ),
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
    );
  }

  // Create from Firestore
  factory FlashcardModel.fromFirestore(Map<String, dynamic> data) {
    final tagData = data['tag'] as Map<String, dynamic>? ?? {};
    
    return FlashcardModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      lessonId: data['lessonId'] as String,
      frontContent: data['frontContent'] as String,
      backContent: data['backContent'] as String,
      tag: FlashcardTag(
        id: tagData['id'] as String? ?? '',
        name: tagData['name'] as String? ?? '',
        emoji: tagData['emoji'] as String? ?? '',
        color: tagData['color'] as String? ?? '#3B82F6',
        description: '', // Will be filled from system tags
        category: _parseTagCategory(tagData['category'] as String?),
      ),
      difficulty: (data['difficulty'] as num?)?.toDouble() ?? 0.5,
      masteryLevel: (data['masteryLevel'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as int?) ?? 0,
      correctCount: (data['correctCount'] as int?) ?? 0,
      isFavorite: data['isFavorite'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      notes: data['notes'] as String?,
      hints: data['hints'] != null 
          ? List<String>.from(data['hints'] as List)
          : null,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      lastReviewedAt: data['lastReviewedAt'] != null
          ? DateTime.parse(data['lastReviewedAt'] as String)
          : null,
      syncStatus: data['syncStatus'] as String? ?? 'synced',
    );
  }

  // Create from domain entity
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
      lastReviewedAt: flashcard.lastReviewedAt,
      reviewCount: flashcard.reviewCount,
      correctCount: flashcard.correctCount,
      isFavorite: flashcard.isFavorite,
      isActive: flashcard.isActive,
      notes: flashcard.notes,
      hints: flashcard.hints,
      syncStatus: flashcard.syncStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Convert to domain entity
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

  // Copy with method
  FlashcardModel copyWith({
    String? id,
    String? lessonId,
    String? userId,
    String? frontContent,
    String? backContent,
    FlashcardTag? tag,
    double? difficulty,
    double? masteryLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReviewedAt,
    int? reviewCount,
    int? correctCount,
    bool? isFavorite,
    bool? isActive,
    String? notes,
    List<String>? hints,
    String? syncStatus,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      userId: userId ?? this.userId,
      frontContent: frontContent ?? this.frontContent,
      backContent: backContent ?? this.backContent,
      tag: tag ?? this.tag,
      difficulty: difficulty ?? this.difficulty,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      hints: hints ?? this.hints,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  static FlashcardTagCategory? _parseTagCategory(String? category) {
    if (category == null) return FlashcardTagCategory.core;
    
    switch (category.toLowerCase()) {
      case 'core':
        return FlashcardTagCategory.core;
      case 'advanced':
        return FlashcardTagCategory.advanced;
      case 'subject':
        return FlashcardTagCategory.subject;
      case 'custom':
        return FlashcardTagCategory.custom;
      default:
        return FlashcardTagCategory.core;
    }
  }
}