// lib/features/auth/domain/usecases/get_current_user.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  Future<Either<AppFailure, User>> call() async {
    return await repository.getCurrentUser();
  }
}
