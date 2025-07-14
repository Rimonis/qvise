// lib/features/content/domain/usecases/update_lesson.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/lesson.dart';
import '../repositories/content_repository.dart';

class UpdateLesson implements UseCase<Lesson, Lesson> {
  final ContentRepository repository;

  UpdateLesson(this.repository);

  @override
  Future<Either<AppError, Lesson>> call(Lesson lesson) async {
    return await repository.updateLesson(lesson);
  }
}
