// lib/features/content/domain/usecases/delete_lesson.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../repositories/content_repository.dart';

class DeleteLessonParams {
  final String lessonId;

  DeleteLessonParams({required this.lessonId});
}

class DeleteLesson implements VoidUseCase<DeleteLessonParams> {
  final ContentRepository repository;

  DeleteLesson(this.repository);

  @override
  Future<Either<AppError, void>> call(DeleteLessonParams params) async {
    return await repository.deleteLesson(params.lessonId);
  }
}
