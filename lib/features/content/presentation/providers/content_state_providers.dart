import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/providers.dart';
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
          // Refresh subjects after deletion
          await refresh();
          // Also refresh other providers
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
          // Refresh topics after deletion
          await refresh();
          // Also refresh subjects to update counts
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
      final createLessonUseCase = ref.read(createLessonProvider);
      final result = await createLessonUseCase(params);
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) async {
          // Refresh lessons after creation
          await refresh();
          // Also refresh topics and subjects to update counts
          ref.invalidate(topicsNotifierProvider);
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
          // Refresh lessons after deletion
          await refresh();
          // Also refresh topics and subjects to update counts
          ref.invalidate(topicsNotifierProvider);
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
      // TODO: Implement lock lesson functionality
      // This will need to update the lesson's isLocked field and set lockedAt
      // For now, just refresh to simulate the change
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

// Network status provider
@riverpod
Stream<bool> networkStatus(Ref ref) {
  final connectionChecker = ref.watch(internetConnectionCheckerProvider);
  return connectionChecker.onStatusChange.map((status) => status == InternetConnectionStatus.connected);
}