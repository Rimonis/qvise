// lib/features/flashcards/application/lesson_event_handler.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/events/event_bus.dart';
import 'package:qvise/core/events/domain_event.dart';
import 'package:qvise/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';

final lessonEventHandlerProvider = Provider((ref) => LessonEventHandler(ref));

class LessonEventHandler {
  final Ref _ref;
  StreamSubscription? _subscription;

  LessonEventHandler(this._ref);

  void initialize() {
    _subscription = _ref.read(eventBusProvider).on<DomainEvent>().listen((event) {
      if (event is LessonDeletedEvent) {
        _handleLessonDeleted(event);
      }
      if (event is TopicDeletedEvent) {
        _handleTopicDeleted(event);
      }
    });
  }

  Future<void> _handleLessonDeleted(LessonDeletedEvent event) async {
    final localDataSource = _ref.read(flashcardLocalDataSourceProvider);
    await localDataSource.deleteFlashcardsByLesson(event.lessonId);
  }

  Future<void> _handleTopicDeleted(TopicDeletedEvent event) async {
    final localDataSource = _ref.read(flashcardLocalDataSourceProvider);
    await localDataSource.deleteFlashcardsByTopic(
      userId: event.userId,
      subjectName: event.subjectName,
      topicName: event.topicName,
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
UI Layer (Refactored)