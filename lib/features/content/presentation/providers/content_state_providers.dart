// lib/features/content/presentation/providers/content_state_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_error_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/create_lesson_params.dart';
import 'content_providers.dart';

part 'content_state_providers.g.dart';

// Due Lessons Provider (for Home tab)
@riverpod
Future<List<Lesson>> dueLessons(Ref ref) async {
  final contentRepository = ref.watch(contentRepositoryProvider);
  final result = await contentRepository.getDueLessons();

  return result.fold(
    (failure) {
      ref.read(contentErrorHandlerProvider.notifier).logError(ContentError.fromFailure(failure));
      throw failure.userFriendlyMessage;
    },
    (lessons) => lessons,
  );
}

// Unlocked Lessons Provider (for Create tab)
@riverpod
Future<List<Lesson>> unlockedLessons(Ref ref) async {
  final contentRepository = ref.watch(contentRepositoryProvider);
  final result = await contentRepository.getAllLessons();

  return result.fold(
    (failure) {
      ref.read(contentErrorHandlerProvider.notifier).logError(ContentError.fromFailure(failure));
      throw failure.userFriendlyMessage;
    },
    (lessons) => lessons.where((lesson) => !lesson.isLocked).toList(),
  );
}

// Provider to fetch a single lesson by ID
@riverpod
Future<Lesson?> lesson(Ref ref, String lessonId) async {
  final contentRepository = ref.watch(contentRepositoryProvider);
  final result = await contentRepository.getLesson(lessonId);
  return result.fold(
    (failure) {
      ref.read(contentErrorHandlerProvider.notifier).logError(ContentError.fromFailure(failure));
      return null;
    },
    (lesson) => lesson,
  );
}

// Subjects Provider
@riverpod
class SubjectsNotifier extends _$SubjectsNotifier {
  @override
  Future<List<Subject>> build() async {
    final getSubjectsUseCase = ref.watch(getSubjectsProvider);
    final result = await getSubjectsUseCase();

    return result.fold(
      (failure) {
        ref.read(contentErrorHandlerProvider.notifier).logError(ContentError.fromFailure(failure));
        throw failure.userFriendlyMessage;
      },
      (subjects) => subjects,
    );
  }

  // ## FIX: The 'handleError' call is removed and logic is handled directly ##
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() async {
      final getSubjectsUseCase = ref.read(getSubjectsProvider);
      final result = await getSubjectsUseCase();
      return result.fold((l) => throw l, (r) => r);
    });

    if (newState.hasError) {
      final contentError = ContentError.fromException(newState.error, newState.stackTrace);
      ref.read(contentErrorHandlerProvider.notifier).logError(contentError);
      state = AsyncValue.error(contentError.userFriendlyMessage, newState.stackTrace ?? StackTrace.current);
    } else {
      state = newState;
    }
  }

  Future<void> deleteSubject(String subjectName) async {
    state = const AsyncValue.loading();
    final deleteSubjectUseCase = ref.read(deleteSubjectProvider);
    final result = await deleteSubjectUseCase(subjectName);

    result.fold(
      (failure) => state = AsyncValue.error(failure.userFriendlyMessage, StackTrace.current),
      (_) {
        ref.invalidateSelf(); // Let the provider rebuild itself
        ref.invalidate(dueLessonsProvider);
        ref.invalidate(unlockedLessonsProvider);
      },
    );
  }
}

// Topics Provider
@riverpod
class TopicsNotifier extends _$TopicsNotifier {
  @override
  Future<List<Topic>> build(String subjectName) async {
    final getTopicsUseCase = ref.watch(getTopicsBySubjectProvider);
    final result = await getTopicsUseCase(subjectName);

    return result.fold(
      (failure) {
        ref.read(contentErrorHandlerProvider.notifier).logError(ContentError.fromFailure(failure));
        throw failure.userFriendlyMessage;
      },
      (topics) => topics,
    );
  }

  // ## FIX: The 'handleError' call is removed and logic is handled directly ##
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() async {
        final getTopicsUseCase = ref.read(getTopicsBySubjectProvider);
        final result = await getTopicsUseCase(subjectName);
        return result.fold((l) => throw l, (r) => r);
    });

    if (newState.hasError) {
      final contentError = ContentError.fromException(newState.error, newState.stackTrace);
      ref.read(contentErrorHandlerProvider.notifier).logError(contentError);
      state = AsyncValue.error(contentError.userFriendlyMessage, newState.stackTrace ?? StackTrace.current);
    } else {
      state = newState;
    }
  }

  Future<void> deleteTopic(String topicName) async {
    state = const AsyncValue.loading();
    final deleteTopicUseCase = ref.read(deleteTopicProvider);
    final result = await deleteTopicUseCase(subjectName, topicName);

    result.fold(
      (failure) => state = AsyncValue.error(failure.userFriendlyMessage, StackTrace.current),
      (_) {
        ref.invalidateSelf();
        ref.invalidate(subjectsNotifierProvider);
        ref.invalidate(dueLessonsProvider);
        ref.invalidate(unlockedLessonsProvider);
      },
    );
  }
}

// Lessons Provider
@riverpod
class LessonsNotifier extends _$LessonsNotifier {
  @override
  Future<List<Lesson>> build({required String subjectName, required String topicName}) async {
    final getLessonsUseCase = ref.watch(getLessonsByTopicProvider);
    final result = await getLessonsUseCase(subjectName, topicName);

    return result.fold(
      (failure) {
        ref.read(contentErrorHandlerProvider.notifier).logError(ContentError.fromFailure(failure));
        throw failure.userFriendlyMessage;
      },
      (lessons) => lessons,
    );
  }

  // ## FIX: The 'handleError' call is removed and logic is handled directly ##
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() async {
        final getLessonsUseCase = ref.read(getLessonsByTopicProvider);
        final result = await getLessonsUseCase(subjectName, topicName);
        return result.fold((l) => throw l, (r) => r);
    });

    if (newState.hasError) {
      final contentError = ContentError.fromException(newState.error, newState.stackTrace);
      ref.read(contentErrorHandlerProvider.notifier).logError(contentError);
      state = AsyncValue.error(contentError.userFriendlyMessage, newState.stackTrace ?? StackTrace.current);
    } else {
      state = newState;
    }
  }

  Future<void> createNewLesson(CreateLessonParams params) async {
    state = const AsyncValue.loading();
    final createLessonUseCase = ref.read(createLessonUseCaseProvider);
    final result = await createLessonUseCase(params);

    result.fold(
      (failure) => state = AsyncValue.error(failure.userFriendlyMessage, StackTrace.current),
      (_) {
        ref.invalidateSelf();
        ref.invalidate(topicsNotifierProvider(params.subjectName));
        ref.invalidate(subjectsNotifierProvider);
        ref.invalidate(dueLessonsProvider);
        ref.invalidate(unlockedLessonsProvider);
      },
    );
  }

  Future<void> deleteLesson(String lessonId) async {
    state = const AsyncValue.loading();
    final deleteLessonUseCase = ref.read(deleteLessonProvider);
    final result = await deleteLessonUseCase(lessonId);

    result.fold(
      (failure) => state = AsyncValue.error(failure.userFriendlyMessage, StackTrace.current),
      (_) {
        ref.invalidateSelf();
        ref.invalidate(topicsNotifierProvider(subjectName));
        ref.invalidate(subjectsNotifierProvider);
        ref.invalidate(dueLessonsProvider);
        ref.invalidate(unlockedLessonsProvider);
      },
    );
  }

  Future<void> lockLesson(String lessonId) async {
    final contentRepository = ref.read(contentRepositoryProvider);
    final result = await contentRepository.lockLesson(lessonId);

    result.fold(
      (failure) => state = AsyncValue.error(failure.userFriendlyMessage, StackTrace.current),
      (_) {
        ref.invalidateSelf();
        ref.invalidate(dueLessonsProvider);
        ref.invalidate(unlockedLessonsProvider);
      },
    );
  }
}

// Selected content providers for navigation
@riverpod
class SelectedSubject extends _$SelectedSubject {
  @override
  Subject? build() => null;
  void select(Subject? subject) => state = subject;
}

@riverpod
class SelectedTopic extends _$SelectedTopic {
  @override
  Topic? build() => null;
  void select(Topic? topic) => state = topic;
}