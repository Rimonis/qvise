// lib/features/content/presentation/providers/content_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:qvise/core/database/database_helper.dart';
import 'package:qvise/core/events/event_bus.dart';
import 'package:qvise/core/providers/providers.dart';
import '../../data/datasources/content_local_data_source.dart';
import '../../data/datasources/content_remote_data_source.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/delete_lesson.dart';
import '../../domain/usecases/delete_topic.dart';
import '../../domain/usecases/get_due_lessons.dart';
import '../../domain/usecases/get_lessons_by_topic.dart';
import '../../domain/usecases/get_subjects.dart';
import '../../domain/usecases/get_topics_by_subject.dart';
import '../../domain/usecases/update_lesson.dart';

part 'content_providers.g.dart';

// Data Sources
@riverpod
ContentLocalDataSource contentLocalDataSource(ContentLocalDataSourceRef ref) {
  return ContentLocalDataSourceImpl(ref.watch(databaseHelperProvider));
}

@riverpod
ContentRemoteDataSource contentRemoteDataSource(ContentRemoteDataSourceRef ref) {
  return ContentRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

// Repository
@riverpod
ContentRepository contentRepository(ContentRepositoryRef ref) {
  return ContentRepositoryImpl(
    localDataSource: ref.watch(contentLocalDataSourceProvider),
    remoteDataSource: ref.watch(contentRemoteDataSourceProvider),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
    eventBus: ref.watch(eventBusProvider),
  );
}

// Use Cases
@riverpod
GetSubjects getSubjects(GetSubjectsRef ref) {
  return GetSubjects(ref.watch(contentRepositoryProvider));
}

@riverpod
GetTopicsBySubject getTopicsBySubject(GetTopicsBySubjectRef ref) {
  return GetTopicsBySubject(ref.watch(contentRepositoryProvider));
}

@riverpod
GetLessonsByTopic getLessonsByTopic(GetLessonsByTopicRef ref) {
  return GetLessonsByTopic(ref.watch(contentRepositoryProvider));
}

@riverpod
GetDueLessons getDueLessons(GetDueLessonsRef ref) {
  return GetDueLessons(ref.watch(contentRepositoryProvider));
}

@riverpod
CreateLesson createLesson(CreateLessonRef ref) {
  return CreateLesson(ref.watch(contentRepositoryProvider));
}

@riverpod
UpdateLesson updateLesson(UpdateLessonRef ref) {
  return UpdateLesson(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteLesson deleteLesson(DeleteLessonRef ref) {
  return DeleteLesson(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteTopic deleteTopic(DeleteTopicRef ref) {
  return DeleteTopic(ref.watch(contentRepositoryProvider));
}

// State Providers (UI Layer)

@riverpod
Future<List<Subject>> subjects(SubjectsRef ref) async {
  final getSubjects = ref.watch(getSubjectsProvider);
  final result = await getSubjects(const NoParams());
  
  return result.fold(
    (error) => throw error, // Throw AppError to be handled by AsyncValue
    (subjects) => subjects,
  );
}

@riverpod
Future<List<Topic>> topicsBySubject(
  TopicsBySubjectRef ref,
  String subjectName,
) async {
  final getTopics = ref.watch(getTopicsBySubjectProvider);
  final result = await getTopics(GetTopicsBySubjectParams(subjectName: subjectName));
  
  return result.fold(
    (error) => throw error,
    (topics) => topics,
  );
}

@riverpod
Future<List<Lesson>> lessonsByTopic(
  LessonsByTopicRef ref,
  String subjectName,
  String topicName,
) async {
  final getLessons = ref.watch(getLessonsByTopicProvider);
  final result = await getLessons(
    GetLessonsByTopicParams(subjectName: subjectName, topicName: topicName),
  );
  
  return result.fold(
    (error) => throw error,
    (lessons) => lessons,
  );
}

@riverpod
Future<List<Lesson>> dueLessons(DueLessonsRef ref) async {
  final getDueLessons = ref.watch(getDueLessonsProvider);
  final result = await getDueLessons(const NoParams());
  
  return result.fold(
    (error) => throw error,
    (lessons) => lessons,
  );
}

// Notifier Providers for State Management

@riverpod
class SubjectsNotifier extends _$SubjectsNotifier {
  @override
  Future<List<Subject>> build() async {
    return ref.watch(subjectsProvider.future);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class TopicsNotifier extends _$TopicsNotifier {
  @override
  Future<List<Topic>> build(String subjectName) async {
    return ref.watch(topicsBySubjectProvider(subjectName).future);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class LessonsNotifier extends _$LessonsNotifier {
  @override
  Future<List<Lesson>> build(String subjectName, String topicName) async {
    return ref.watch(lessonsByTopicProvider(subjectName, topicName).future);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> createLesson(CreateLessonParams params) async {
    final createUseCase = ref.read(createLessonProvider);
    final result = await createUseCase(params);
    
    result.fold(
      (error) => throw error,
      (_) => refresh(), // Refresh the list after creation
    );
  }

  Future<void> deleteLesson(String lessonId) async {
    final deleteUseCase = ref.read(deleteLessonProvider);
    final result = await deleteUseCase(DeleteLessonParams(lessonId: lessonId));
    
    result.fold(
      (error) => throw error,
      (_) => refresh(), // Refresh the list after deletion
    );
  }
}

@riverpod
class DueLessonsNotifier extends _$DueLessonsNotifier {
  @override
  Future<List<Lesson>> build() async {
    return ref.watch(dueLessonsProvider.future);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Computed/Derived Providers

@riverpod
Future<Map<String, int>> subjectStats(SubjectStatsRef ref) async {
  try {
    final subjects = await ref.watch(subjectsProvider.future);
    
    return {
      'totalSubjects': subjects.length,
      'totalTopics': subjects.fold<int>(0, (sum, subject) => sum + subject.topicCount),
      'totalLessons': subjects.fold<int>(0, (sum, subject) => sum + subject.lessonCount),
      'averageProficiency': subjects.isEmpty 
          ? 0 
          : (subjects.fold<double>(0, (sum, subject) => sum + subject.proficiency) / subjects.length * 100).round(),
    };
  } catch (e) {
    return {
      'totalSubjects': 0,
      'totalTopics': 0,
      'totalLessons': 0,
      'averageProficiency': 0,
    };
  }
}

@riverpod
Future<int> dueLessonCount(DueLessonCountRef ref) async {
  try {
    final lessons = await ref.watch(dueLessonsProvider.future);
    return lessons.length;
  } catch (e) {
    return 0;
  }
}

// Content Search Provider
@riverpod
Future<List<Lesson>> searchLessons(
  SearchLessonsRef ref,
  String query,
) async {
  if (query.trim().isEmpty) return [];
  
  try {
    final repository = ref.watch(contentRepositoryProvider);
    final result = await repository.getAllLessons();
    
    return result.fold(
      (error) => throw error,
      (lessons) => lessons.where((lesson) {
        final titleMatch = lesson.title?.toLowerCase().contains(query.toLowerCase()) ?? false;
        final subjectMatch = lesson.subjectName.toLowerCase().contains(query.toLowerCase());
        final topicMatch = lesson.topicName.toLowerCase().contains(query.toLowerCase());
        
        return titleMatch || subjectMatch || topicMatch;
      }).toList(),
    );
  } catch (e) {
    return [];
  }
}
