// lib/features/content/presentation/providers/content_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import '../../data/datasources/content_local_data_source.dart';
import '../../data/datasources/content_remote_data_source.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/delete_lesson.dart';
import '../../domain/usecases/delete_subject.dart';
import '../../domain/usecases/delete_topic.dart';
import '../../domain/usecases/get_lessons_by_topic.dart';
import '../../domain/usecases/get_subjects.dart';
import '../../domain/usecases/get_topics_by_subject.dart';

part 'content_providers.g.dart';

@riverpod
ContentLocalDataSource contentLocalDataSource(ContentLocalDataSourceRef ref) {
  return ContentLocalDataSourceImpl();
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
    flashcardLocalDataSource: ref.watch(flashcardLocalDataSourceProvider),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
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
CreateLesson createLessonUseCase(CreateLessonUseCaseRef ref) {
  return CreateLesson(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteSubject deleteSubject(DeleteSubjectRef ref) {
  return DeleteSubject(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteTopic deleteTopic(DeleteTopicRef ref) {
  return DeleteTopic(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteLesson deleteLesson(DeleteLessonRef ref) {
  return DeleteLesson(ref.watch(contentRepositoryProvider));
}
