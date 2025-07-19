// lib/features/files/domain/usecases/sync_files.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/file_repository.dart';

class SyncFiles {
  final FileRepository repository;

  SyncFiles(this.repository);

  Future<Either<AppFailure, void>> call() async {
    return await repository.syncFiles();
  }
}