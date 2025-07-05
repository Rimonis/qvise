// lib/features/content/presentation/providers/content_state_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      if (kDebugMode) print('Failed to load due lessons: ${failure.message}');
      throw Exception(failure.message);
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
      if (kDebugMode) print('Failed to load lessons: ${failure.message}');
      throw Exception(failure.message);
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
    (failure) => null,
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
        if (kDebugMode) print('Failed to load subjects: ${failure.message}');
        throw Exception(failure.message);
      },
      (subjects) => subjects,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getSubjectsUseCase = ref.read(getSubjectsProvider);
      final result = await getSubjectsUseCase();

      return result.fold(
        (failure) => throw Exception(failure.message),
        (subjects) => subjects,
      );
    });
  }

  Future<void> deleteSubject(String subjectName) async {
    state = const AsyncValue.loading();

    try {
      final deleteSubjectUseCase = ref.read(deleteSubjectProvider);
      final result = await deleteSubjectUseCase(subjectName);

      result.fold(
        (failure) => throw Exception(failure.message),
        (_) async {
          await refresh();
          ref.invalidate(dueLessonsProvider);
          ref.invalidate(unlockedLessonsProvider);
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
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
        if (kDebugMode) print('Failed to load topics: ${failure.message}');
        throw Exception(failure.message);
      },
      (topics) => topics,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getTopicsUseCase = ref.read(getTopicsBySubjectProvider);
      final result = await getTopicsUseCase(subjectName);

      return result.fold(
        (failure) => throw Exception(failure.message),
        (topics) => topics,
      );
    });
  }

  Future<void> deleteTopic(String topicName) async {
    state = const AsyncValue.loading();

    try {
      final deleteTopicUseCase = ref.read(deleteTopicProvider);
      final result = await deleteTopicUseCase(subjectName, topicName);

      result.fold(
        (failure) => throw Exception(failure.message),
        (_) async {
          await refresh();
          ref.invalidate(subjectsNotifierProvider);
          ref.invalidate(dueLessonsProvider);
          ref.invalidate(unlockedLessonsProvider);
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Lessons Provider
@riverpod
class LessonsNotifier extends _$LessonsNotifier {
  @override
  Future<List<Lesson>> build(String subjectName, String topicName) async {
    final getLessonsUseCase = ref.watch(getLessonsByTopicProvider);
    final result = await getLessonsUseCase(subjectName, topicName);

    return result.fold(
      (failure) {
        if (kDebugMode) print('Failed to load lessons: ${failure.message}');
        throw Exception(failure.message);
      },
      (lessons) => lessons,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getLessonsUseCase = ref.read(getLessonsByTopicProvider);
      final result = await getLessonsUseCase(subjectName, topicName);

      return result.fold(
        (failure) => throw Exception(failure.message),
        (lessons) => lessons,
      );
    });
  }

  Future<void> createNewLesson(CreateLessonParams params) async {
    state = const AsyncValue.loading();

    try {
      final createLessonUseCase = ref.read(createLessonUseCaseProvider);
      final result = await createLessonUseCase(params);

      result.fold(
        (failure) => throw Exception(failure.message),
        (_) async {
          await refresh();
          ref.invalidate(topicsNotifierProvider(params.subjectName));
          ref.invalidate(subjectsNotifierProvider);
          ref.invalidate(dueLessonsProvider);
          ref.invalidate(unlockedLessonsProvider);
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    state = const AsyncValue.loading();

    try {
      final deleteLessonUseCase = ref.read(deleteLessonProvider);
      final result = await deleteLessonUseCase(lessonId);

      result.fold(
        (failure) => throw Exception(failure.message),
        (_) async {
          await refresh();
          ref.invalidate(topicsNotifierProvider(subjectName));
          ref.invalidate(subjectsNotifierProvider);
          ref.invalidate(dueLessonsProvider);
          ref.invalidate(unlockedLessonsProvider);
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> lockLesson(String lessonId) async {
    try {
      final contentRepository = ref.read(contentRepositoryProvider);
      await contentRepository.lockLesson(lessonId);
      await refresh();
      ref.invalidate(dueLessonsProvider);
      ref.invalidate(unlockedLessonsProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Selected content providers for navigation
@riverpod
class SelectedSubject extends _$SelectedSubject {
  @override
  Subject? build() => null;

  void select(Subject? subject) {
    state = subject;
  }
}

@riverpod
class SelectedTopic extends _$SelectedTopic {
  @override
  Topic? build() => null;

  void select(Topic? topic) {
    state = topic;
  }
}