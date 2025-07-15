// lib/features/auth/domain/usecases/send_email_verification.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../repositories/auth_repository.dart';

class SendEmailVerification {
  final AuthRepository repository;

  SendEmailVerification(this.repository);

  Future<Either<AppFailure, void>> call() async {
    return await repository.sendEmailVerification();
  }
}
