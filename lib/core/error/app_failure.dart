// lib/core/error/app_failure.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

enum FailureType {
  network,
  server,
  auth,
  cache,
  validation,
  conflict,
  notFound,
  sync,
  unknown,
}

class AppFailure {
  final FailureType type;
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;
  
  const AppFailure({
    required this.message,
    this.type = FailureType.unknown,
    this.code,
    this.originalException,
    this.stackTrace,
    this.metadata,
  });

  factory AppFailure.fromException(Object e, [StackTrace? s]) {
    if (e is AppFailure) {
      return e;
    }

    if (e is FirebaseException) {
      return AppFailure(
        type: FailureType.server,
        message: e.message ?? 'An unknown Firebase error occurred.',
        code: e.code,
        originalException: e,
        stackTrace: s,
      );
    }

    if (e is SocketException) {
      return AppFailure(
        type: FailureType.network,
        message: 'No internet connection. Please check your network.',
        originalException: e,
        stackTrace: s,
      );
    }
    
    // Default case for any other exception
    return AppFailure(
      message: 'An unexpected error occurred: ${e.toString()}',
      originalException: e,
      stackTrace: s,
    );
  }

  String get userFriendlyMessage {
    switch (type) {
      case FailureType.network:
        return 'Connection error. Please check your internet.';
      case FailureType.server:
        return code == '500' 
          ? 'Server maintenance in progress. Please try again later.'
          : 'A server error occurred. Please try again.';
      case FailureType.auth:
        return 'Authentication error. Please sign in to continue.';
      case FailureType.validation:
        final fields = metadata?['fields'] as Map<String, String>?;
        if (fields != null && fields.isNotEmpty) {
          return 'Please check the following fields: ${fields.keys.join(', ')}';
        }
        return 'Invalid input. Please check the form and try again.';
      case FailureType.conflict:
        return 'This item was modified by another device. Please refresh and try again.';
      case FailureType.sync:
        return 'Sync in progress. Your changes have been saved locally and will sync shortly.';
      case FailureType.notFound:
        return 'The requested content could not be found.';
      case FailureType.cache:
        return 'A local data storage error occurred. Please restart the app.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
  
  bool get isRetryable => const [
    FailureType.network,
    FailureType.server,
    FailureType.sync,
  ].contains(type);

  @override
  String toString() {
    return 'AppFailure(type: $type, message: $message, code: $code)';
  }
}
