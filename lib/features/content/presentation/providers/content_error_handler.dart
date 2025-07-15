// lib/features/content/presentation/providers/content_error_handler.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_error_handler.g.dart';

// Error types specific to content feature
enum ContentErrorType {
  network,
  serverError,
  notFound,
  unauthorized,
  validation,
  localStorageError,
  syncError,
  unknown,
}

class ContentError {
  final ContentErrorType type;
  final String message;
  final String? details;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  ContentError({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  factory ContentError.fromFailure(AppFailure failure) {
    ContentErrorType errorType;
    switch(failure.type) {
      case FailureType.network:
        errorType = ContentErrorType.network;
        break;
      case FailureType.server:
        errorType = ContentErrorType.serverError;
        break;
      case FailureType.auth:
        errorType = ContentErrorType.unauthorized;
        break;
      case FailureType.cache:
        errorType = ContentErrorType.localStorageError;
        break;
      case FailureType.validation:
        errorType = ContentErrorType.validation;
        break;
      case FailureType.sync:
         errorType = ContentErrorType.syncError;
         break;
      case FailureType.notFound:
        errorType = ContentErrorType.notFound;
        break;
      case FailureType.unknown:
      case FailureType.conflict:
      default:
        errorType = ContentErrorType.unknown;
        break;
    }

    return ContentError(
      type: errorType,
      message: failure.message,
      details: failure.userFriendlyMessage,
      originalError: failure.originalException,
      stackTrace: failure.stackTrace,
    );
  }

  factory ContentError.fromException(dynamic exception, [StackTrace? stack]) {
    final failure = AppFailure.fromException(exception, stack);
    return ContentError.fromFailure(failure);
  }

  String get userFriendlyMessage {
    switch (type) {
      case ContentErrorType.network:
        return 'No internet connection. Please check your network settings.';
      case ContentErrorType.serverError:
        return 'Server is temporarily unavailable. Please try again later.';
      case ContentErrorType.notFound:
        return 'The requested content could not be found.';
      case ContentErrorType.unauthorized:
        return 'You need to sign in to access this content.';
      case ContentErrorType.validation:
        return 'Invalid data. Please check your input and try again.';
      case ContentErrorType.localStorageError:
        return 'Error accessing local storage. Please try again.';
      case ContentErrorType.syncError:
        return 'Sync failed. Your changes will be synced when connection is restored.';
      case ContentErrorType.unknown:
        return details ?? 'Something went wrong. Please try again.';
    }
  }

  bool get isRetryable {
    return const [
      ContentErrorType.network,
      ContentErrorType.serverError,
      ContentErrorType.syncError,
    ].contains(type);
  }
}

// Global error handler for content providers
@Riverpod(keepAlive: true)
class ContentErrorHandler extends _$ContentErrorHandler {
  final List<ContentError> _errorHistory = [];
  static const int maxHistorySize = 50;

  @override
  List<ContentError> build() {
    return [];
  }

  void logError(ContentError error) {
    _errorHistory.add(error);
    if (_errorHistory.length > maxHistorySize) {
      _errorHistory.removeAt(0);
    }
    state = List.from(_errorHistory);

    if (kDebugMode) {
      print('ContentError [${error.type}]: ${error.message}');
      if (error.details != null) print('Details: ${error.details}');
      if (error.stackTrace != null) print(error.stackTrace);
    }
  }

  void clearErrors() {
    _errorHistory.clear();
    state = [];
  }
}

// Extension to handle errors in providers easily
extension AsyncValueErrorHandling<T> on AsyncValue<T> {
  AsyncValue<T> handleError(Ref ref) {
    return maybeWhen(
      error: (error, stack) {
        final contentError = ContentError.fromException(error, stack);
        ref.read(contentErrorHandlerProvider.notifier).logError(contentError);
        return AsyncValue<T>.error(contentError.userFriendlyMessage, stack);
      },
      orElse: () => this,
    );
  }
}