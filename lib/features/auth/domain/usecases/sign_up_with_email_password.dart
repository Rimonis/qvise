// lib/features/auth/domain/usecases/sign_up_with_email_password.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailPasswordParams {
  final String email;
  final String password;
  final String displayName;

  SignUpWithEmailPasswordParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class SignUpWithEmailPassword implements UseCase<User, SignUpWithEmailPasswordParams> {
  final AuthRepository repository;

  SignUpWithEmailPassword(this.repository);

  @override
  Future<Either<AppError, User>> call(SignUpWithEmailPasswordParams params) async {
    return await repository.signUpWithEmailPassword(
      params.email,
      params.password,
      params.displayName,
    );
  }
}
