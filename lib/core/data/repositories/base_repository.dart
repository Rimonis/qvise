// lib/core/data/repositories/base_repository.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';

abstract class BaseRepository {
  /// A utility method to wrap repository calls with a standardized error handling mechanism.
  /// It catches common exceptions and converts them into a structured [AppFailure].
  Future<Either<AppFailure, T>> guard<T>(Future<T> Function() future) async {
    try {
      return Right(await future());
    } catch (e, s) {
      return Left(AppFailure.fromException(e, s));
    }
  }
}
