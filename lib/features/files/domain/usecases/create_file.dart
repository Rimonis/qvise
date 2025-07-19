// lib/features/files/domain/usecases/create_file.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/file.dart';
import '../repositories/file_repository.dart';

class CreateFile {
  final FileRepository repository;

  CreateFile(this.repository);

  Future<Either<AppFailure, FileEntity>> call(CreateFileParams params) async {
    return await repository.createFile(
      lessonId: params.lessonId,
      localPath: params.localPath,
    );
  }
}

class CreateFileParams {
  final String lessonId;
  final String localPath;

  const CreateFileParams({required this.lessonId, required this.localPath});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateFileParams &&
        other.lessonId == lessonId &&
        other.localPath == localPath;
  }

  @override
  int get hashCode => Object.hash(lessonId, localPath);
}