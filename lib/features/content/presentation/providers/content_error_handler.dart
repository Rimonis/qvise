import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';

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
  
  factory ContentError.fromFailure(Failure failure) {
    ContentErrorType type;
    String details = '';
    
    switch (failure.runtimeType) {
      case NetworkFailure:
        type = ContentErrorType.network;
        details = 'Please check your internet connection';
        break;
      case ServerFailure:
        type = ContentErrorType.serverError;
        details = 'Our servers are experiencing issues. Please try again later';
        break;
      case CacheFailure:
        type = ContentErrorType.localStorageError;
        details = 'Error accessing local storage';
        break;
      case AuthFailure:
        type = ContentErrorType.unauthorized;
        details = 'Please sign in again to continue';
        break;
      default:
        type = ContentErrorType.unknown;
        details = 'An unexpected error occurred';
    }
    
    return ContentError(
      type: type,
      message: failure.message,
      details: details,
    );
  }
  
  factory ContentError.fromException(dynamic exception, [StackTrace? stack]) {
    if (kDebugMode) {
      print('ContentError.fromException: $exception');
      if (stack != null) print(stack);
    }
    
    String message;
    ContentErrorType type;
    
    if (exception is NetworkFailure) {
      return ContentError.fromFailure(exception);
    }
    
    if (exception.toString().contains('NetworkException') ||
        exception.toString().contains('SocketException')) {
      type = ContentErrorType.network;
      message = 'Network connection error';
    } else if (exception.toString().contains('TimeoutException')) {
      type = ContentErrorType.network;
      message = 'Request timed out';
    } else if (exception.toString().contains('FormatException')) {
      type = ContentErrorType.validation;
      message = 'Invalid data format';
    } else if (exception.toString().contains('404')) {
      type = ContentErrorType.notFound;
      message = 'Content not found';
    } else if (exception.toString().contains('401') || 
               exception.toString().contains('403')) {
      type = ContentErrorType.unauthorized;
      message = 'Access denied';
    } else if (exception.toString().contains('500') ||
               exception.toString().contains('502') ||
               exception.toString().contains('503')) {
      type = ContentErrorType.serverError;
      message = 'Server error';
    } else {
      type = ContentErrorType.unknown;
      message = exception.toString();
    }
    
    return ContentError(
      type: type,
      message: message,
      originalError: exception,
      stackTrace: stack,
    );
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
    switch (type) {
      case ContentErrorType.network:
      case ContentErrorType.serverError:
      case ContentErrorType.syncError:
        return true;
      case ContentErrorType.notFound:
      case ContentErrorType.unauthorized:
      case ContentErrorType.validation:
      case ContentErrorType.localStorageError:
      case ContentErrorType.unknown:
        return false;
    }
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
    
    // Keep history size limited
    if (_errorHistory.length > maxHistorySize) {
      _errorHistory.removeAt(0);
    }
    
    // Update state to trigger UI updates if needed
    state = List.from(_errorHistory);
    
    // Log to console in debug mode
    if (kDebugMode) {
      print('ContentError [${error.type}]: ${error.message}');
      if (error.details != null) print('Details: ${error.details}');
      if (error.stackTrace != null) print(error.stackTrace);
    }
    
    // TODO: Send to crash reporting service in production
  }
  
  void clearErrors() {
    _errorHistory.clear();
    state = [];
  }
  
  List<ContentError> getRecentErrors({int count = 10}) {
    final start = (_errorHistory.length - count).clamp(0, _errorHistory.length);
    return _errorHistory.sublist(start);
  }
  
  ContentError? getLastError() {
    return _errorHistory.isNotEmpty ? _errorHistory.last : null;
  }
  
  List<ContentError> getErrorsByType(ContentErrorType type) {
    return _errorHistory.where((error) => error.type == type).toList();
  }
}

// Extension to handle errors in providers easily
extension AsyncValueErrorHandling<T> on AsyncValue<T> {
  AsyncValue<T> handleError(WidgetRef ref) {
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

// Retry helper
class RetryHelper {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);
  
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    required ContentErrorHandler errorHandler,
    int maxAttempts = maxRetries,
    bool Function(dynamic)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e, stack) {
        attempt++;
        
        final error = ContentError.fromException(e, stack);
        
        // Check if we should retry
        final shouldRetry = retryIf?.call(e) ?? error.isRetryable;
        
        if (attempt >= maxAttempts || !shouldRetry) {
          errorHandler.logError(error);
          rethrow;
        }
        
        // Log retry attempt
        if (kDebugMode) {
          print('Retry attempt $attempt/$maxAttempts after ${delay.inSeconds}s');
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
    
    throw Exception('Max retries exceeded');
  }
}