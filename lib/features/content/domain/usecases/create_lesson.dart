// lib/features/content/domain/usecases/create_lesson.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/entities/create_lesson_params.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';

class CreateLesson {
  final ContentRepository repository;

  CreateLesson(this.repository);

  Future<Either<AppFailure, Lesson>> call(CreateLessonParams params) async {
    return await repository.createLesson(params);
  }
}
