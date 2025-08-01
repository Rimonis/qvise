// lib/features/files/presentation/providers/file_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:qvise/core/data/providers/data_providers.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/services/subscription_service.dart';
import 'package:qvise/core/services/user_service.dart';
import '../../data/datasources/file_remote_data_source.dart';
import '../../data/repositories/file_repository_impl.dart';
import '../../domain/entities/file.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/usecases/create_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_providers.g.dart';

// Define ToggleFileStarredParams class
class ToggleFileStarredParams {
  final String fileId;
  final bool isStarred;

  const ToggleFileStarredParams({
    required this.fileId,
    required this.isStarred,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToggleFileStarredParams &&
        other.fileId == fileId &&
        other.isStarred == isStarred;
  }

  @override
  int get hashCode => Object.hash(fileId, isStarred);
}

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

// --- State Management (Direct Repository Access Only) ---

// Files for a specific lesson
@riverpod
class LessonFiles extends _$LessonFiles {
  late String _lessonId;

  @override
  Future<List<FileEntity>> build(String lessonId) async {
    _lessonId = lessonId;
    final repository = ref.read(fileRepositoryProvider);
    final result = await repository.getFilesByLesson(lessonId);
    return result.fold(
      (failure) => throw failure,
      (files) => files,
    );
  }

  Future<void> addFile(String localPath) async {
    final repository = ref.read(fileRepositoryProvider);
    final result = await repository.createFile(
      lessonId: _lessonId,
      localPath: localPath,
    );
    
    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> removeFile(String fileId) async {
    final repository = ref.read(fileRepositoryProvider);
    final result = await repository.deleteFile(fileId);
    
    result.fold(
      (failure) => throw failure,
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> starFile(String fileId, bool isStarred) async {
    final repository = ref.read(fileRepositoryProvider);
    final result = await repository.toggleFileStarred(fileId, isStarred);
    
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
    final repository = ref.read(fileRepositoryProvider);
    final result = await repository.getStarredFiles();
    return result.fold(
      (failure) => throw failure,
      (files) => files,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// --- State Notifiers for UI Operations ---
@riverpod
class CreateFileNotifier extends _$CreateFileNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createFile(CreateFileParams params) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(fileRepositoryProvider);
      final result = await repository.createFile(
        lessonId: params.lessonId,
        localPath: params.localPath,
      );
      
      result.fold(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (_) => state = const AsyncValue.data(null),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

@riverpod
class DeleteFileNotifier extends _$DeleteFileNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> deleteFile(String fileId) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(fileRepositoryProvider);
      final result = await repository.deleteFile(fileId);
      
      result.fold(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (_) => state = const AsyncValue.data(null),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

@riverpod
class ToggleFileStarredNotifier extends _$ToggleFileStarredNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> toggleStarred(ToggleFileStarredParams params) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(fileRepositoryProvider);
      final result = await repository.toggleFileStarred(params.fileId, params.isStarred);
      
      result.fold(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (_) => state = const AsyncValue.data(null),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}