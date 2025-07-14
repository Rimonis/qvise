// lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/app_error.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Either<AppError, Type>> call(Params params);
}

/// Use case for operations that don't require parameters
class NoParams extends Equatable {
  const NoParams();
  
  @override
  List<Object> get props => [];
}

/// Base class for synchronous use cases
abstract class SyncUseCase<Type, Params> {
  Either<AppError, Type> call(Params params);
}

/// Base class for stream-based use cases
abstract class StreamUseCase<Type, Params> {
  Stream<Either<AppError, Type>> call(Params params);
}

/// Base class for use cases that return void
abstract class VoidUseCase<Params> {
  Future<Either<AppError, void>> call(Params params);
}

/// Helper extensions for use cases
extension UseCaseExtensions<T> on UseCase<T, NoParams> {
  /// Call the use case without parameters
  Future<Either<AppError, T>> execute() => call(const NoParams());
}

extension VoidUseCaseExtensions on VoidUseCase<NoParams> {
  /// Call the void use case without parameters
  Future<Either<AppError, void>> execute() => call(const NoParams());
}
