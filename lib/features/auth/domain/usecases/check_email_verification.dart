// lib/features/auth/domain/usecases/check_email_verification.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/auth_repository.dart';

class CheckEmailVerification {
  final AuthRepository repository;

  CheckEmailVerification(this.repository);

  Future<Either<AppFailure, bool>> call() async {
    return await repository.checkEmailVerification();
  }
}
