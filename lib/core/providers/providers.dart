// lib/core/providers/providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:qvise/core/database/database_helper.dart';
import 'package:qvise/core/security/field_encryption.dart';

// Firebase Providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: ['email', 'profile'],
  );
});

// Database Provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Network Provider
final internetConnectionCheckerProvider = Provider<InternetConnectionChecker>((ref) {
  return InternetConnectionChecker();
});

// Security Provider
final fieldEncryptionProvider = Provider<FieldEncryption>((ref) {
  return FieldEncryption();
});

// User Provider (Current authenticated user)
final currentUserProvider = StreamProvider<User?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges();
});

// Authentication state provider
final authStateProvider = StateProvider<AuthenticationState>((ref) {
  return AuthenticationState.initial;
});

enum AuthenticationState {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

// App lifecycle provider
final appLifecycleProvider = StateProvider<AppLifecycleState>((ref) {
  return AppLifecycleState.resumed;
});

enum AppLifecycleState {
  resumed,
  inactive,
  paused,
  detached,
}

// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

enum ThemeMode {
  system,
  light,
  dark,
}

// Connectivity provider
final connectivityProvider = StreamProvider<bool>((ref) {
  final checker = ref.watch(internetConnectionCheckerProvider);
  return checker.onStatusChange.map((status) => 
    status == InternetConnectionStatus.connected);
});

// App configuration provider
final appConfigProvider = Provider<AppConfiguration>((ref) {
  return const AppConfiguration(
    enableAnalytics: true,
    enableCrashReporting: true,
    maxOfflineDataAge: Duration(days: 30),
    syncBatchSize: 50,
    maxRetryAttempts: 3,
  );
});

class AppConfiguration {
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final Duration maxOfflineDataAge;
  final int syncBatchSize;
  final int maxRetryAttempts;

  const AppConfiguration({
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.maxOfflineDataAge,
    required this.syncBatchSize,
    required this.maxRetryAttempts,
  });
}

// Performance monitoring provider
final performanceProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor();
});

class PerformanceMonitor {
  void trackOperation(String operation, Duration duration) {
    // Implementation for tracking performance metrics
  }

  void trackError(String operation, dynamic error) {
    // Implementation for tracking errors
  }

  void trackUserAction(String action) {
    // Implementation for tracking user actions
  }
}

// Cache provider
final cacheProvider = Provider<CacheManager>((ref) {
  return CacheManager();
});

class CacheManager {
  final Map<String, CacheEntry> _cache = {};

  void put<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = CacheEntry(
      value: value,
      expiry: ttl != null ? DateTime.now().add(ttl) : null,
    );
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.expiry != null && DateTime.now().isAfter(entry.expiry!)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T?;
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime? expiry;

  CacheEntry({required this.value, this.expiry});
}

// Logger provider
final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

class AppLogger {
  void debug(String message, [Map<String, dynamic>? extra]) {
    _log('DEBUG', message, extra);
  }

  void info(String message, [Map<String, dynamic>? extra]) {
    _log('INFO', message, extra);
  }

  void warning(String message, [Map<String, dynamic>? extra]) {
    _log('WARNING', message, extra);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message, {
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
    });
  }

  void _log(String level, String message, Map<String, dynamic>? extra) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] $level: $message');
    if (extra != null) {
      print('  Extra: $extra');
    }
  }
}

// Notification provider
final notificationProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  void showSuccess(String message) {
    // Implementation for success notifications
  }

  void showError(String message) {
    // Implementation for error notifications
  }

  void showInfo(String message) {
    // Implementation for info notifications
  }

  void showWarning(String message) {
    // Implementation for warning notifications
  }
}
