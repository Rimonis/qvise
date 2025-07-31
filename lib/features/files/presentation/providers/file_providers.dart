// lib/features/files/presentation/providers/file_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:qvise/core/data/providers/data_providers.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/services/subscription_service.dart';
import 'package:qvise/core/services/user_service.dart';
import '../../data/datasources/file_local_data_source.dart';
import '../../data/datasources/file_remote_data_source.dart';
import '../../data/repositories/file_repository_impl.dart';
import '../../domain/entities/file.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/usecases/create_file.dart';
import '../../domain/usecases/delete_file.dart';
import '../../domain/usecases/delete_files_by_lesson.dart';
import '../../domain/usecases/get_files_by_lesson.dart';
import '../../domain/usecases/get_starred_files.dart';
import '../../domain/usecases/sync_files.dart';
import '../../domain/usecases/toggle_file_starred.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Export the params class for use in widgets
export '../../domain/usecases/toggle_file_starred.dart' show ToggleFileStarredParams;

part 'file_providers.g.dart';

// --- Core Services ---
@riverpod
FilePickerService filePickerService(Ref ref) {
  return FilePickerService();
}

@riverpod
SubscriptionService subscriptionService(Ref ref) {
  return MockSubscriptionService();
}

@riverpod
UserService userService(Ref ref) {
  return UserServiceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
}

// --- Data Sources ---
@riverpod
FileLocalDataSource fileLocalDataSource(Ref ref) {
  return FileLocalDataSourceImpl();
}

@riverpod
FileRemoteDataSource fileRemoteDataSource(Ref ref) {
  return FileRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: null, // Add firebase_storage when package is added
  );
}

// --- Repository ---
@riverpod
FileRepository fileRepository(Ref ref) {
  return FileRepositoryImpl(
    localDataSource: ref.watch(fileLocalDataSourceProvider),
    remoteDataSource: ref.watch(fileRemoteDataSourceProvider),
    unitOfWork: ref.watch(unitOfWorkProvider),
    subscriptionService: ref.watch(subscriptionServiceProvider),
    userService: ref.watch(userServiceProvider),
    uuid: const Uuid(),
  );
}

// --- Use Cases ---
@riverpod
CreateFile createFileProvider(Ref ref) {
  return CreateFile(ref.watch(fileRepositoryProvider));
}

@riverpod
DeleteFile deleteFileProvider(Ref ref) {
  return DeleteFile(ref.watch(fileRepositoryProvider));
}

@riverpod
DeleteFilesByLesson deleteFilesByLessonProvider(Ref ref) {
  return DeleteFilesByLesson(ref.watch(fileRepositoryProvider));
}

@riverpod
GetFilesByLesson getFilesByLessonProvider(Ref ref) {
  return GetFilesByLesson(ref.watch(fileRepositoryProvider));
}

@riverpod
GetStarredFiles getStarredFilesProvider(Ref ref) {
  return GetStarredFiles(ref.watch(fileRepositoryProvider));
}

@riverpod
SyncFiles syncFilesProvider(Ref ref) {
  return SyncFiles(ref.watch(fileRepositoryProvider));
}

@riverpod
ToggleFileStarred toggleFileStarredProvider(Ref ref) {
  return ToggleFileStarred(ref.watch(fileRepositoryProvider));
}

// --- State Management ---

// Files for a specific lesson
@riverpod
class LessonFiles extends _$LessonFiles {
  late String _lessonId;

  @override
  Future<List<FileEntity>> build(String lessonId) async {
    _lessonId = lessonId;
    final useCase = ref.read(getFilesByLessonProvider);
    final result = await useCase(lessonId);
    return result.fold(
      (failure) => throw failure,
      (files) => files,
    );
  }

  Future<void> addFile(String localPath) async {
    final useCase = ref.read(createFileProvider);
    final params = CreateFileParams(lessonId: _lessonId, localPath: localPath);
    final result = await useCase(params);
    
    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> removeFile(String fileId) async {
    final useCase = ref.read(deleteFileProvider);
    final result = await useCase(fileId);
    
    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> starFile(String fileId, bool isStarred) async {
    final useCase = ref.read(toggleFileStarredProvider);
    final params = ToggleFileStarredParams(fileId: fileId, isStarred: isStarred);
    final result = await useCase(params);
    
    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }
}

// Starred files provider
@riverpod
class StarredFiles extends _$StarredFiles {
  @override
  Future<List<FileEntity>> build() async {
    final useCase = ref.read(getStarredFilesProvider);
    final result = await useCase();
    return result.fold(
      (failure) => throw failure,
      (files) => files,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}