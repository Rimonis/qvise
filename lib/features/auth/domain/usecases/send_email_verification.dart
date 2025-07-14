// lib/features/auth/domain/usecases/send_email_verification.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendEmailVerification implements VoidUseCase<NoParams> {
  final AuthRepository repository;

  SendEmailVerification(this.repository);

  @override
  Future<Either<AppError, void>> call(NoParams params) async {
    return await repository.sendEmailVerification();
  }
}
