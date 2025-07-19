// lib/features/files/domain/usecases/get_files_by_lesson.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/file.dart';
import '../repositories/file_repository.dart';

class GetFilesByLesson {
  final FileRepository repository;

  GetFilesByLesson(this.repository);

  Future<Either<AppFailure, List<FileEntity>>> call(String lessonId) async {
    return await repository.getFilesByLesson(lessonId);
  }
}