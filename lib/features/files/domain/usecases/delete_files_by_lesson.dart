// lib/features/files/domain/usecases/delete_files_by_lesson.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/file_repository.dart';

class DeleteFilesByLesson {
  final FileRepository repository;

  DeleteFilesByLesson(this.repository);

  Future<Either<AppFailure, void>> call(String lessonId) async {
    return await repository.deleteFilesByLesson(lessonId);
  }
}