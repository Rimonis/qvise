// lib/features/auth/domain/usecases/check_email_verification.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckEmailVerification implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  CheckEmailVerification(this.repository);

  @override
  Future<Either<AppError, bool>> call(NoParams params) async {
    return await repository.checkEmailVerification();
  }
}
