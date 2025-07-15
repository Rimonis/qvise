// lib/features/content/domain/usecases/get_topics_by_subject.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/entities/topic.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';

class GetTopicsBySubject {
  final ContentRepository repository;

  GetTopicsBySubject(this.repository);

  Future<Either<AppFailure, List<Topic>>> call(String subjectName) async {
    return await repository.getTopicsBySubject(subjectName);
  }
}