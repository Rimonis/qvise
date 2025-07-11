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

part 'content_providers.g.dart';

@riverpod
ContentLocalDataSource contentLocalDataSource(ContentLocalDataSourceRef ref) {
  return ContentLocalDataSourceImpl(ref.watch(databaseHelperProvider));
}

@riverpod
ContentRemoteDataSource contentRemoteDataSource(ContentRemoteDataSourceRef ref) {
  return ContentRemoteDataSourceImpl(
      firestore: ref.watch(firebaseFirestoreProvider));
}

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
DeleteLesson deleteLesson(DeleteLessonRef ref) {
  return DeleteLesson(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteTopic deleteTopic(DeleteTopicRef ref) {
  return DeleteTopic(ref.watch(contentRepositoryProvider));
}