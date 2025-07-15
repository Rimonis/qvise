// lib/features/auth/domain/usecases/sign_up_with_email_password.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailPassword {
  final AuthRepository repository;

  SignUpWithEmailPassword(this.repository);

  Future<Either<AppFailure, User>> call(String email, String password, String displayName) async {
    return await repository.signUpWithEmailPassword(email, password, displayName);
  }
}