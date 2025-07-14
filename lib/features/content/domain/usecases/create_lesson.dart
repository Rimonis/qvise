// lib/features/content/domain/usecases/create_lesson.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/lesson.dart';
import '../entities/create_lesson_params.dart';
import '../repositories/content_repository.dart';

class CreateLesson implements UseCase<Lesson, CreateLessonParams> {
  final ContentRepository repository;

  CreateLesson(this.repository);

  @override
  Future<Either<AppError, Lesson>> call(CreateLessonParams params) async {
    return await repository.createLesson(params);
  }
}
