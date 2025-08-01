// lib/features/files/domain/repositories/file_repository.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/file.dart';

abstract class FileRepository {
  Future<Either<AppFailure, FileEntity>> createFile({
    required String lessonId,
    required String localPath,
  });

  Future<Either<AppFailure, List<FileEntity>>> getFilesByLesson(String lessonId);
  
  Future<Either<AppFailure, List<FileEntity>>> getStarredFiles();

  Future<Either<AppFailure, void>> toggleFileStarred(String fileId, bool isStarred);

  Future<Either<AppFailure, void>> deleteFile(String fileId);

  Future<Either<AppFailure, void>> deleteFilesByLesson(String lessonId);

  Future<Either<AppFailure, void>> syncFiles();
}