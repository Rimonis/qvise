// lib/features/auth/domain/usecases/sign_in_with_google.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  Future<Either<AppFailure, User>> call() async {
    return await repository.signInWithGoogle();
  }
}
