// lib/features/files/data/repositories/file_repository_impl.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qvise/core/data/repositories/base_repository.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/core/services/subscription_service.dart';
import 'package:qvise/core/services/user_service.dart';
import '../../domain/entities/file.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/file_local_data_source.dart';
import '../datasources/file_remote_data_source.dart';
import '../models/file_model.dart';

class FileRepositoryImpl extends BaseRepository implements FileRepository {
  final FileLocalDataSource localDataSource;
  final FileRemoteDataSource remoteDataSource;
  final IUnitOfWork unitOfWork;
  final SubscriptionService subscriptionService;
  final UserService userService;
  final Uuid uuid;

  FileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.unitOfWork,
    required this.subscriptionService,
    required this.userService,
    required this.uuid,
  });

  FileType _determineFileType(String extension) {
    final ext = extension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      return FileType.image;
    }
    if (ext == '.pdf') {
      return FileType.pdf;
    }
    if (['.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx', '.txt'].contains(ext)) {
      return FileType.document;
    }
    return FileType.other;
  }

  @override
  Future<Either<AppFailure, FileEntity>> createFile({
    required String lessonId,
    required String localPath,
  }) async {
    return guard(() async {
      final originalFile = File(localPath);

      if (!await originalFile.exists()) {
        throw const AppFailure(
          type: FailureType.cache,
          message: 'File does not exist at the specified path',
        );
      }

      final fileStat = await originalFile.stat();
      final fileName = p.basename(originalFile.path);
      final fileExtension = p.extension(originalFile.path);

      // Create a permanent copy in the app's directory
      final appDir = await getApplicationDocumentsDirectory();
      final newId = uuid.v4();
      final newFileName = '$newId$fileExtension';
      final permanentPath = p.join(appDir.path, 'files', newFileName);

      // Ensure the directory exists
      await Directory(p.dirname(permanentPath)).create(recursive: true);
      final permanentFile = await originalFile.copy(permanentPath);

      final hasSubscription = await subscriptionService.hasActiveSubscription();
      final userId = await userService.getCurrentUserId();

      final fileModel = FileModel(
        id: newId,
        userId: userId,
        lessonId: lessonId,
        name: fileName,
        filePath: permanentFile.path,
        fileType: _determineFileType(fileExtension).name,
        fileSize: fileStat.size,
        isStarred: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        syncStatus: hasSubscription ? 'queued' : 'local_only',
        version: 1,
      );

      // Perform DB operations in a transaction
      await unitOfWork.transaction(() async {
        await unitOfWork.file.createFile(fileModel);

        // Update lesson file count
        final lesson = await unitOfWork.content.getLesson(lessonId);
        if (lesson != null) {
          await unitOfWork.content.insertOrUpdateLesson(
            lesson.copyWith(fileCount: lesson.fileCount + 1),
          );
        }
      });

      // Attempt sync if premium (fire and forget)
      if (hasSubscription) {
        syncFiles();
      }

      return fileModel.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteFile(String fileId) async {
    return guard(() async {
      final fileModel = await localDataSource.getFileById(fileId);
      if (fileModel == null) {
        throw const AppFailure(
          type: FailureType.cache,
          message: 'File not found',
        );
      }

      // Perform DB operations in a transaction
      await unitOfWork.transaction(() async {
        await unitOfWork.file.deleteFile(fileId);

        // Update lesson file count
        final lesson = await unitOfWork.content.getLesson(fileModel.lessonId);
        if (lesson != null) {
          await unitOfWork.content.insertOrUpdateLesson(
            lesson.copyWith(fileCount: lesson.fileCount - 1),
          );
        }
      });

      // Delete local file from storage
      final localFile = File(fileModel.filePath);
      if (await localFile.exists()) {
        try {
          await localFile.delete();
        } catch (e) {
          // Log error but don't fail the operation
          debugPrint('Failed to delete local file: $e');
        }
      }

      // Delete from remote storage if it was synced
      if (fileModel.remoteUrl != null) {
        try {
          await remoteDataSource.deleteFile(fileId, fileModel.userId);
        } catch (e) {
          // Log error but don't fail the operation
          debugPrint('Failed to delete remote file: $e');
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteFilesByLesson(String lessonId) async {
    return guard(() async {
      // Get all files for this lesson
      final fileModels = await localDataSource.getFilesByLessonId(lessonId);
      if (fileModels.isEmpty) return;

      final userId = await userService.getCurrentUserId();

      // Delete local files from storage
      for (final fileModel in fileModels) {
        final localFile = File(fileModel.filePath);
        if (await localFile.exists()) {
          try {
            await localFile.delete();
          } catch (e) {
            debugPrint('Failed to delete local file ${fileModel.name}: $e');
          }
        }
      }

      // Delete from local database (this will be handled by foreign key cascade)
      await localDataSource.deleteFilesByLesson(lessonId);

      // Delete from remote storage and Firestore
      try {
        await remoteDataSource.deleteFilesByLesson(lessonId, userId);
      } catch (e) {
        debugPrint('Failed to delete remote files for lesson $lessonId: $e');
      }

      // Update lesson file count
      final lesson = await unitOfWork.content.getLesson(lessonId);
      if (lesson != null) {
        await unitOfWork.content.insertOrUpdateLesson(
          lesson.copyWith(fileCount: 0),
        );
      }
    });
  }

  @override
  Future<Either<AppFailure, List<FileEntity>>> getFilesByLesson(String lessonId) async {
    return guard(() async {
      final fileModels = await localDataSource.getFilesByLessonId(lessonId);
      return fileModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<FileEntity>>> getStarredFiles() async {
    return guard(() async {
      final fileModels = await localDataSource.getStarredFiles();
      return fileModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, void>> syncFiles() async {
    return guard(() async {
      final hasSubscription = await subscriptionService.hasActiveSubscription();
      if (!hasSubscription) {
        throw const AppFailure(
          type: FailureType.validation,
          message: 'Premium subscription required for file sync',
        );
      }

      final filesToSync = await localDataSource.getFilesForSync();

      for (final file in filesToSync) {
        try {
          // Mark as uploading
          await localDataSource.updateFile(
            file.copyWith(syncStatus: 'uploading'),
          );

          // Upload and get updated model
          final syncedFile = await remoteDataSource.uploadFile(file);

          // Update local record with synced data
          await localDataSource.updateFile(syncedFile);
        } catch (e) {
          // Mark as failed on error
          await localDataSource.updateFile(
            file.copyWith(syncStatus: 'failed'),
          );
          // Continue with next file
          debugPrint('Failed to sync file ${file.id}: $e');
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> toggleFileStarred(String fileId, bool isStarred) async {
    return guard(() async {
      final fileModel = await localDataSource.getFileById(fileId);
      if (fileModel == null) {
        throw const AppFailure(
          type: FailureType.cache,
          message: 'File not found',
        );
      }

      final hasSubscription = await subscriptionService.hasActiveSubscription();
      final shouldQueueSync = fileModel.remoteUrl != null && hasSubscription;

      final updatedModel = fileModel.copyWith(
        isStarred: isStarred ? 1 : 0,
        syncStatus: shouldQueueSync ? 'queued' : fileModel.syncStatus,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await localDataSource.updateFile(updatedModel);

      // Attempt sync if needed (fire and forget)
      if (shouldQueueSync) {
        syncFiles();
      }
    });
  }
}