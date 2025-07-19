// lib/features/files/domain/usecases/toggle_file_starred.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/file_repository.dart';

class ToggleFileStarred {
  final FileRepository repository;

  ToggleFileStarred(this.repository);

  Future<Either<AppFailure, void>> call(ToggleFileStarredParams params) async {
    return await repository.toggleFileStarred(params.fileId, params.isStarred);
  }
}

class ToggleFileStarredParams {
  final String fileId;
  final bool isStarred;

  const ToggleFileStarredParams({required this.fileId, required this.isStarred});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToggleFileStarredParams &&
        other.fileId == fileId &&
        other.isStarred == isStarred;
  }

  @override
  int get hashCode => Object.hash(fileId, isStarred);
}