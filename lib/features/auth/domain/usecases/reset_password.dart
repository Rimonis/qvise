// lib/features/auth/domain/usecases/reset_password.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository repository;

  ResetPassword(this.repository);

  Future<Either<AppFailure, void>> call(String email) async {
    return await repository.sendPasswordResetEmail(email);
  }
}
