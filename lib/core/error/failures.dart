// lib/core/error/failures.dart

import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network connection failed',
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error occurred',
    super.code = 'SERVER_ERROR',
    super.details,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timeout',
    super.code = 'TIMEOUT_ERROR',
    super.details,
  });
}

/// Cache/Local storage failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache operation failed',
    super.code = 'CACHE_ERROR',
    super.details,
  });
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database operation failed',
    super.code = 'DATABASE_ERROR',
    super.details,
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
    super.code = 'AUTH_ERROR',
    super.details,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Unauthorized access',
    super.code = 'UNAUTHORIZED',
    super.details,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Validation failed',
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure({
    super.message = 'Invalid input provided',
    super.code = 'INVALID_INPUT',
    super.details,
  });
}

/// Content-specific failures
class ContentNotFoundFailure extends Failure {
  const ContentNotFoundFailure({
    super.message = 'Content not found',
    super.code = 'CONTENT_NOT_FOUND',
    super.details,
  });
}

class ContentAlreadyExistsFailure extends Failure {
  const ContentAlreadyExistsFailure({
    super.message = 'Content already exists',
    super.code = 'CONTENT_EXISTS',
    super.details,
  });
}

class SyncFailure extends Failure {
  const SyncFailure({
    super.message = 'Synchronization failed',
    super.code = 'SYNC_ERROR',
    super.details,
  });
}

/// File operation failures
class FileFailure extends Failure {
  const FileFailure({
    super.message = 'File operation failed',
    super.code = 'FILE_ERROR',
    super.details,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Permission denied',
    super.code = 'PERMISSION_DENIED',
    super.details,
  });
}

/// Generic failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    super.code = 'UNKNOWN_ERROR',
    super.details,
  });
}

class NotImplementedFailure extends Failure {
  const NotImplementedFailure({
    super.message = 'Feature not implemented',
    super.code = 'NOT_IMPLEMENTED',
    super.details,
  });
}

/// Utility class for creating failures from exceptions
class FailureFactory {
  static Failure fromException(Exception exception) {
    if (exception.toString().contains('SocketException')) {
      return const NetworkFailure();
    } else if (exception.toString().contains('TimeoutException')) {
      return const TimeoutFailure();
    } else if (exception.toString().contains('FormatException')) {
      return const ValidationFailure();
    } else {
      return UnknownFailure(
        message: exception.toString(),
        details: exception,
      );
    }
  }

  static Failure fromError(Error error) {
    return UnknownFailure(
      message: error.toString(),
      details: error,
    );
  }
}

/// Extension methods for easier failure handling
extension FailureExtensions on Failure {
  bool get isNetworkFailure => this is NetworkFailure;
  bool get isServerFailure => this is ServerFailure;
  bool get isAuthFailure => this is AuthFailure;
  bool get isCacheFailure => this is CacheFailure;
  bool get isValidationFailure => this is ValidationFailure;
  
  String get userFriendlyMessage {
    switch (runtimeType) {
      case NetworkFailure:
        return 'Please check your internet connection';
      case ServerFailure:
        return 'Server is temporarily unavailable';
      case AuthFailure:
        return 'Please sign in again';
      case ValidationFailure:
        return 'Please check your input';
      case ContentNotFoundFailure:
        return 'Content not found';
      default:
        return message;
    }
  }
}
