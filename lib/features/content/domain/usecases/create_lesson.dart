import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/entities/create_lesson_params.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../../../../core/error/failures.dart';


class CreateLesson {
  final ContentRepository repository;

  CreateLesson(this.repository);

  Future<Either<Failure, Lesson>> call(CreateLessonParams params) async {
    return await repository.createLesson(params);
  }
}