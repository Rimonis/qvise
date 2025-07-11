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
      unknown: (message, _) => 'An unexpected error occurred. Please try again.',
    );
  }
}