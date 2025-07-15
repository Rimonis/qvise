// lib/features/auth/domain/usecases/sign_in_with_email_password.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailPassword {
  final AuthRepository repository;

  SignInWithEmailPassword(this.repository);

  Future<Either<AppFailure, User>> call(String email, String password) async {
    return await repository.signInWithEmailPassword(email, password);
  }
}
