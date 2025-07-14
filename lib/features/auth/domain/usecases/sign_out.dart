// lib/features/auth/domain/usecases/sign_out.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOut implements VoidUseCase<NoParams> {
  final AuthRepository repository;

  SignOut(this.repository);

  @override
  Future<Either<AppError, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}
