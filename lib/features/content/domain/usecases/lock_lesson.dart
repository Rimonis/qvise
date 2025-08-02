// lib/features/content/domain/usecases/lock_lesson.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/content_repository.dart';

class LockLesson {
  final ContentRepository repository;

  LockLesson(this.repository);

  @override
  Future<Either<AppFailure, void>> call(String lessonId) async {
    return await repository.lockLesson(lessonId);
  }
}