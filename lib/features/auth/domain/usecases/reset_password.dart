// lib/features/auth/domain/usecases/reset_password.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  final String email;

  ResetPasswordParams({required this.email});
}

class ResetPassword implements VoidUseCase<ResetPasswordParams> {
  final AuthRepository repository;

  ResetPassword(this.repository);

  @override
  Future<Either<AppError, void>> call(ResetPasswordParams params) async {
    return await repository.sendPasswordResetEmail(params.email);
  }
}
