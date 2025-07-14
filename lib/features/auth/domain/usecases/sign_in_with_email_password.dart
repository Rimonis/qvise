// lib/features/auth/domain/usecases/sign_in_with_email_password.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailPasswordParams {
  final String email;
  final String password;

  SignInWithEmailPasswordParams({
    required this.email,
    required this.password,
  });
}

class SignInWithEmailPassword implements UseCase<User, SignInWithEmailPasswordParams> {
  final AuthRepository repository;

  SignInWithEmailPassword(this.repository);

  @override
  Future<Either<AppError, User>> call(SignInWithEmailPasswordParams params) async {
    return await repository.signInWithEmailPassword(params.email, params.password);
  }
}
