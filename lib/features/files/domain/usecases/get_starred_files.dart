// lib/features/files/domain/usecases/get_starred_files.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/file.dart';
import '../repositories/file_repository.dart';

class GetStarredFiles {
  final FileRepository repository;

  GetStarredFiles(this.repository);

  Future<Either<AppFailure, List<FileEntity>>> call() async {
    return await repository.getStarredFiles();
  }
}