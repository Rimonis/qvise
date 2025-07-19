// lib/features/files/presentation/providers/file_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
import '../../domain/usecases/get_files_by_lesson.dart';
import '../../domain/usecases/get_starred_files.dart';
import '../../domain/usecases/sync_files.dart';
import '../../domain/usecases/toggle_file_starred.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

// --- Data Layer ---
@riverpod
FileRemoteDataSource fileRemoteDataSource(Ref ref) {
  return FileRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    storage: MockFirebaseStorage(), // Use mock for now since package not added
  );
}

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
GetFilesByLesson getFilesByLesson(Ref ref) {
  return GetFilesByLesson(ref.watch(fileRepositoryProvider));
}

@riverpod
GetStarredFiles getStarredFiles(Ref ref) {
  return GetStarredFiles(ref.watch(fileRepositoryProvider));
}

@riverpod
CreateFile createFile(Ref ref) {
  return CreateFile(ref.watch(fileRepositoryProvider));
}

@riverpod
DeleteFile deleteFile(Ref ref) {
  return DeleteFile(ref.watch(fileRepositoryProvider));
}

@riverpod
ToggleFileStarred toggleFileStarred(Ref ref) {
  return ToggleFileStarred(ref.watch(fileRepositoryProvider));
}

@riverpod
SyncFiles syncFiles(Ref ref) {
  return SyncFiles(ref.watch(fileRepositoryProvider));
}

// --- State Notifiers ---

// Files for a specific lesson
@riverpod
class LessonFiles extends _$LessonFiles {
  @override
  Future<List<FileEntity>> build(String lessonId) async {
    final useCase = ref.watch(getFilesByLessonProvider);
    final result = await useCase(lessonId);
    return result.fold(
      (failure) => throw failure,
      (files) => files,
    );
  }

  Future<void> addFile(String localPath) async {
    final useCase = ref.read(createFileProvider);
    final params = CreateFileParams(lessonId: lessonId, localPath: localPath);
    final result = await useCase(params);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> deleteFile(String fileId) async {
    final useCase = ref.read(deleteFileProvider);
    final result = await useCase(fileId);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> toggleStar(String fileId, bool currentStatus) async {
    final useCase = ref.read(toggleFileStarredProvider);
    final params = ToggleFileStarredParams(fileId: fileId, isStarred: !currentStatus);
    final result = await useCase(params);

    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }
}

// Starred files for the Browse tab
@riverpod
class StarredFiles extends _$StarredFiles {
  @override
  Future<List<FileEntity>> build() async {
    final useCase = ref.watch(getStarredFilesProvider);
    final result = await useCase();
    return result.fold(
      (failure) => throw failure,
      (files) => files,
    );
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

// Mock Firebase Storage for development until package is added
class MockFirebaseStorage {
  // This is a placeholder until firebase_storage is added to pubspec.yaml
  // Once the package is added, replace this with the actual FirebaseStorage.instance
}