import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/providers.dart';
import '../../data/datasources/content_local_data_source.dart';
import '../../data/datasources/content_remote_data_source.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/usecases/get_subjects.dart';
import '../../domain/usecases/get_topics_by_subject.dart';
import '../../domain/usecases/get_lessons_by_topic.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/delete_lesson.dart';
import '../../domain/usecases/delete_topic.dart';
import '../../domain/usecases/delete_subject.dart';

part 'content_providers.g.dart';

// Data sources
@Riverpod(keepAlive: true)
ContentLocalDataSource contentLocalDataSource(Ref ref) {
  final dataSource = ContentLocalDataSourceImpl();
  // Initialize database on creation
  dataSource.initDatabase();
  return dataSource;
}

@Riverpod(keepAlive: true)
ContentRemoteDataSource contentRemoteDataSource(Ref ref) {
  return ContentRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

// Repository
@Riverpod(keepAlive: true)
ContentRepository contentRepository(Ref ref) {
  return ContentRepositoryImpl(
    localDataSource: ref.watch(contentLocalDataSourceProvider),
    remoteDataSource: ref.watch(contentRemoteDataSourceProvider),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
}

// Use cases
@Riverpod(keepAlive: true)
GetSubjects getSubjects(Ref ref) {
  return GetSubjects(ref.watch(contentRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetTopicsBySubject getTopicsBySubject(Ref ref) {
  return GetTopicsBySubject(ref.watch(contentRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetLessonsByTopic getLessonsByTopic(Ref ref) {
  return GetLessonsByTopic(ref.watch(contentRepositoryProvider));
}

@Riverpod(keepAlive: true)
CreateLesson createLesson(Ref ref) {
  return CreateLesson(ref.watch(contentRepositoryProvider));
}

@Riverpod(keepAlive: true)
DeleteLesson deleteLesson(Ref ref) {
  return DeleteLesson(ref.watch(contentRepositoryProvider));
}

@Riverpod(keepAlive: true)
DeleteTopic deleteTopic(Ref ref) {
  return DeleteTopic(ref.watch(contentRepositoryProvider));
}

@Riverpod(keepAlive: true)
DeleteSubject deleteSubject(Ref ref) {
  return DeleteSubject(ref.watch(contentRepositoryProvider));
}