// lib/features/files/domain/usecases/delete_file.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/file_repository.dart';

class DeleteFile {
  final FileRepository repository;

  DeleteFile(this.repository);

  Future<Either<AppFailure, void>> call(String fileId) async {
    return await repository.deleteFile(fileId);
  }
}