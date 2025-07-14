// lib/core/error/app_error.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
sealed class AppError with _$AppError {
  const AppError._();

  /// Error indicating a problem with the network connection.
  const factory AppError.network({
    required String message,
    @Default(true) bool isRetryable,
  }) = _NetworkError;

  /// Error indicating a problem with the server (e.g., 5xx status codes).
  const factory AppError.server({
    required String message,
    int? statusCode,
    @Default(true) bool isRetryable,
  }) = _ServerError;

  /// Error indicating a problem with the local cache or database.
  const factory AppError.database({
    required String message,
    @Default(false) bool isRetryable,
  }) = _DatabaseError;

  /// Error related to authentication (e.g., invalid credentials, session expired).
  const factory AppError.auth({
    required String message,
    @Default(false) bool isRetryable,
  }) = _AuthError;

  /// Error indicating a data synchronization conflict or failure.
  const factory AppError.sync({
    required String message,
    @Default(true) bool isRetryable,
  }) = _SyncError;

  /// Error indicating content was not found.
  const factory AppError.notFound({
    required String message,
    String? entityType,
    String? entityId,
    @Default(false) bool isRetryable,
  }) = _NotFoundError;

  /// Error indicating validation failed.
  const factory AppError.validation({
    required String message,
    Map<String, String>? fieldErrors,
    @Default(false) bool isRetryable,
  }) = _ValidationError;

  /// Error indicating content already exists (conflict).
  const factory AppError.conflict({
    required String message,
    @Default(false) bool isRetryable,
  }) = _ConflictError;

  /// Error indicating insufficient permissions.
  const factory AppError.permission({
    required String message,
    @Default(false) bool isRetryable,
  }) = _PermissionError;

  /// Error indicating a timeout occurred.
  const factory AppError.timeout({
    required String message,
    @Default(true) bool isRetryable,
  }) = _TimeoutError;

  /// Error indicating a file operation failed.
  const factory AppError.file({
    required String message,
    String? filePath,
    @Default(false) bool isRetryable,
  }) = _FileError;

  /// An unknown or unexpected error.
  const factory AppError.unknown({
    required String message,
    @Default(false) bool isRetryable,
  }) = _UnknownError;

  /// Provides a user-friendly message for each error type.
  String get userFriendlyMessage {
    return when(
      network: (message, _) => 'Network error. Please check your connection and try again.',
      server: (message, code, _) => 'A server error occurred. Please try again later.',
      database: (message, _) => 'A local data error occurred. Please restart the app.',
      auth: (message, _) => message, // Auth errors often have user-friendly messages already.
      sync: (message, _) => 'Data sync failed. Some data may be out of date.',
      notFound: (message, type, id, _) => type != null ? '$type not found.' : 'Content not found.',
      validation: (message, errors, _) => 'Please check your input and try again.',
      conflict: (message, _) => 'This item already exists.',
      permission: (message, _) => 'You don\'t have permission to perform this action.',
      timeout: (message, _) => 'Request timed out. Please try again.',
      file: (message, path, _) => 'File operation failed.',
      unknown: (message, _) => 'An unexpected error occurred. Please try again.',
    );
  }

  /// Check if this error type typically indicates a network issue
  bool get isNetworkRelated => when(
    network: (_, __) => true,
    server: (_, __, ___) => true,
    timeout: (_, __) => true,
    sync: (_, __) => true,
    auth: (_, __) => false,
    database: (_, __) => false,
    notFound: (_, __, ___, ____) => false,
    validation: (_, __, ___) => false,
    conflict: (_, __) => false,
    permission: (_, __) => false,
    file: (_, __, ___) => false,
    unknown: (_, __) => false,
  );

  /// Check if this error suggests user action is required
  bool get requiresUserAction => when(
    network: (_, __) => true,
    server: (_, __, ___) => false,
    database: (_, __) => true,
    auth: (_, __) => true,
    sync: (_, __) => false,
    notFound: (_, __, ___, ____) => true,
    validation: (_, __, ___) => true,
    conflict: (_, __) => true,
    permission: (_, __) => true,
    timeout: (_, __) => true,
    file: (_, __, ___) => true,
    unknown: (_, __) => false,
  );
}

/// Utility class for creating AppError from exceptions
class AppErrorFactory {
  static AppError fromException(Exception exception) {
    final errorString = exception.toString().toLowerCase();
    
    if (errorString.contains('socketexception') || 
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return AppError.network(message: exception.toString());
    } else if (errorString.contains('timeout')) {
      return AppError.timeout(message: exception.toString());
    } else if (errorString.contains('formatexception') ||
               errorString.contains('validation')) {
      return AppError.validation(message: exception.toString());
    } else if (errorString.contains('permission') ||
               errorString.contains('access denied')) {
      return AppError.permission(message: exception.toString());
    } else if (errorString.contains('file') ||
               errorString.contains('path')) {
      return AppError.file(message: exception.toString());
    } else {
      return AppError.unknown(message: exception.toString());
    }
  }

  static AppError fromError(Error error) {
    return AppError.unknown(message: error.toString());
  }
}

/// Extension methods for easier error handling
extension AppErrorExtensions on AppError {
  bool get isNetworkError => this is _NetworkError;
  bool get isServerError => this is _ServerError;
  bool get isAuthError => this is _AuthError;
  bool get isDatabaseError => this is _DatabaseError;
  bool get isValidationError => this is _ValidationError;
  bool get isNotFoundError => this is _NotFoundError;
  bool get isConflictError => this is _ConflictError;
  bool get isSyncError => this is _SyncError;
}
