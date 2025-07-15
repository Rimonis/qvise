// lib/features/auth/domain/usecases/sign_out.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository repository;

  SignOut(this.repository);

  Future<Either<AppFailure, void>> call() async {
    return await repository.signOut();
  }
}
