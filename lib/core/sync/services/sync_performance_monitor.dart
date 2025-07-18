// lib/core/sync/services/sync_performance_monitor.dart
import 'package:flutter/foundation.dart';

class SyncPerformanceMonitor {
  final _metrics = <String, Duration>{};

  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      _metrics[operationName] = stopwatch.elapsed;
      if (kDebugMode) {
        print('$operationName took ${stopwatch.elapsedMilliseconds}ms');
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      _metrics['$operationName-failed'] = stopwatch.elapsed;
      rethrow;
    }
  }

  Map<String, Duration> get metrics => Map.unmodifiable(_metrics);

  void logSummary() {
    print('=== Sync Performance Summary ===');
    _metrics.forEach((operation, duration) {
      print('$operation: ${duration.inMilliseconds}ms');
    });
    final total =
        _metrics.values.fold<Duration>(Duration.zero, (a, b) => a + b);
    print('Total sync time: ${total.inSeconds}s');
  }
}
