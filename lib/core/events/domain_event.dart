// lib/core/events/domain_event.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain_event.freezed.dart';

/// Base class for all domain events
abstract class DomainEvent {
  const DomainEvent();
  
  DateTime get occurredAt => DateTime.now();
  String get eventId => DateTime.now().millisecondsSinceEpoch.toString();
}

/// Lesson-related events
@freezed
class LessonCreatedEvent extends DomainEvent with _$LessonCreatedEvent {
  const factory LessonCreatedEvent({
    required String lessonId,
    required String userId,
    required String subjectName,
    required String topicName,
    String? title,
  }) = _LessonCreatedEvent;
}

@freezed
class LessonUpdatedEvent extends DomainEvent with _$LessonUpdatedEvent {
  const factory LessonUpdatedEvent({
    required String lessonId,
    required String userId,
    required Map<String, dynamic> changes,
  }) = _LessonUpdatedEvent;
}

@freezed
class LessonDeletedEvent extends DomainEvent with _$LessonDeletedEvent {
  const factory LessonDeletedEvent({
    required String lessonId,
    required String userId,
    required String subjectName,
    required String topicName,
  }) = _LessonDeletedEvent;
}

@freezed
class LessonReviewedEvent extends DomainEvent with _$LessonReviewedEvent {
  const factory LessonReviewedEvent({
    required String lessonId,
    required String userId,
    required double oldProficiency,
    required double newProficiency,
    required DateTime nextReviewDate,
  }) = _LessonReviewedEvent;
}

/// Topic-related events
@freezed
class TopicCreatedEvent extends DomainEvent with _$TopicCreatedEvent {
  const factory TopicCreatedEvent({
    required String userId,
    required String subjectName,
    required String topicName,
  }) = _TopicCreatedEvent;
}

@freezed
class TopicDeletedEvent extends DomainEvent with _$TopicDeletedEvent {
  const factory TopicDeletedEvent({
    required String userId,
    required String subjectName,
    required String topicName,
  }) = _TopicDeletedEvent;
}

/// Subject-related events
@freezed
class SubjectCreatedEvent extends DomainEvent with _$SubjectCreatedEvent {
  const factory SubjectCreatedEvent({
    required String userId,
    required String subjectName,
  }) = _SubjectCreatedEvent;
}

@freezed
class SubjectDeletedEvent extends DomainEvent with _$SubjectDeletedEvent {
  const factory SubjectDeletedEvent({
    required String userId,
    required String subjectName,
  }) = _SubjectDeletedEvent;
}

/// Flashcard-related events
@freezed
class FlashcardCreatedEvent extends DomainEvent with _$FlashcardCreatedEvent {
  const factory FlashcardCreatedEvent({
    required String flashcardId,
    required String lessonId,
    required String userId,
  }) = _FlashcardCreatedEvent;
}

@freezed
class FlashcardDeletedEvent extends DomainEvent with _$FlashcardDeletedEvent {
  const factory FlashcardDeletedEvent({
    required String flashcardId,
    required String lessonId,
    required String userId,
  }) = _FlashcardDeletedEvent;
}

/// Sync-related events
@freezed
class SyncStartedEvent extends DomainEvent with _$SyncStartedEvent {
  const factory SyncStartedEvent({
    required String userId,
    required String syncType, // 'full', 'incremental', 'manual'
  }) = _SyncStartedEvent;
}

@freezed
class SyncCompletedEvent extends DomainEvent with _$SyncCompletedEvent {
  const factory SyncCompletedEvent({
    required String userId,
    required String syncType,
    required int itemsSynced,
    required Duration duration,
    required bool success,
    String? errorMessage,
  }) = _SyncCompletedEvent;
}
