// lib/core/application/sync_coordinator.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/application/sync_state.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/core/sync/services/sync_service.dart';
import 'dart:math';

final syncCoordinatorProvider =
    StateNotifierProvider<SyncCoordinator, SyncState>((ref) {
  return SyncCoordinator(ref);
});

class SyncCoordinator extends StateNotifier<SyncState> {
  final Ref _ref;
  SyncService? _syncService;
  int _retryCount = 0;
  Timer? _retryTimer;

  SyncCoordinator(this._ref) : super(const SyncState.idle()) {
    _ref.listen(syncServiceProvider.future, (_, next) async {
      _syncService = await next;
    });

    // Listen for network changes to trigger sync
    _ref.listen<AsyncValue<bool>>(networkStatusProvider, (previous, next) {
      final isOnline = next.valueOrNull ?? false;
      final wasOnline = previous?.valueOrNull ?? false;
      if (isOnline && !wasOnline) {
        syncAll();
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> syncAll() async {
    if (state.whenOrNull(syncing: () => true) ?? false) return;
    if (_syncService == null) return;

    state = const SyncState.syncing();
    _retryTimer?.cancel();

    final result = await _syncService!.performSync();

    result.fold(
      (failure) {
        state = SyncState.error(failure);
        if (failure.isRetryable) {
          _retryCount++;
          // Exponential backoff: 30s, 60s, 120s, 240s, 300s (max 5 minutes)
          final delay = min(30 * pow(2, _retryCount - 1), 300).toInt();
          _retryTimer = Timer(Duration(seconds: delay), syncAll);
        }
      },
      (report) {
        _retryCount = 0; // Reset retry count on success
        if (report.hasUnresolvedConflicts) {
          state = SyncState.hasConflicts(report.unresolvedConflicts);
        } else if (report.isSuccessful) {
          state = SyncState.success(report);
        } else {
          state = const SyncState.error(AppFailure(
              type: FailureType.sync,
              message: 'Sync completed with errors'));
        }
      },
    );

    // Revert to idle state after a short delay, unless there are conflicts
    if (mounted && (state.whenOrNull(hasConflicts: (_) => true) ?? false) == false) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          state = const SyncState.idle();
        }
      });
    }
  }
}
