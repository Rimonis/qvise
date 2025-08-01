// lib/features/content/presentation/providers/content_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/data/providers/data_providers.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
ContentRemoteDataSource contentRemoteDataSource(Ref ref) {
  return ContentRemoteDataSourceImpl(
      firestore: ref.watch(firebaseFirestoreProvider));
}

@riverpod
ContentRepository contentRepository(Ref ref) {
  return ContentRepositoryImpl(
    localDataSource: ref.watch(contentLocalDataSourceProvider),
    remoteDataSource: ref.watch(contentRemoteDataSourceProvider),
    unitOfWork: ref.watch(unitOfWorkProvider),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
}

@riverpod
GetSubjects getSubjects(Ref ref) {
  return GetSubjects(ref.watch(contentRepositoryProvider));
}

@riverpod
GetTopicsBySubject getTopicsBySubject(Ref ref) {
  return GetTopicsBySubject(ref.watch(contentRepositoryProvider));
}

@riverpod
GetLessonsByTopic getLessonsByTopic(Ref ref) {
  return GetLessonsByTopic(ref.watch(contentRepositoryProvider));
}

@riverpod
CreateLesson createLessonUseCase(Ref ref) {
  return CreateLesson(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteSubject deleteSubject(Ref ref) {
  return DeleteSubject(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteTopic deleteTopic(Ref ref) {
  return DeleteTopic(ref.watch(contentRepositoryProvider));
}

@riverpod
DeleteLesson deleteLesson(Ref ref) {
  return DeleteLesson(ref.watch(contentRepositoryProvider));
}