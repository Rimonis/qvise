// lib/features/content/domain/usecases/delete_lesson.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';

class DeleteLesson {
  final ContentRepository repository;

  DeleteLesson(this.repository);

  Future<Either<AppFailure, void>> call(String lessonId) async {
    return await repository.deleteLesson(lessonId);
  }
}
