// lib/core/application/sync_coordinator.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/application/sync_state.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/core/sync/services/sync_service.dart';

final syncCoordinatorProvider =
    StateNotifierProvider<SyncCoordinator, SyncState>((ref) {
  return SyncCoordinator(ref);
});

class SyncCoordinator extends StateNotifier<SyncState> {
  final Ref _ref;
  SyncService? _syncService;

  SyncCoordinator(this._ref) : super(const SyncState.idle()) {
    _ref.listen(syncServiceProvider.future, (_, next) async {
      _syncService = await next;
    });
  }

  Future<void> syncAll() async {
    if (state.whenOrNull(syncing: () => true) ?? false) return;
    if (_syncService == null) return;

    state = const SyncState.syncing();

    final result = await _syncService!.performSync();

    result.fold(
      (failure) {
        state = SyncState.error(failure);
        if (failure.isRetryable) {
          Future.delayed(const Duration(seconds: 30), syncAll);
        }
      },
      (report) {
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

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && (state.whenOrNull(hasConflicts: (_) => true) ?? false) == false) {
        state = const SyncState.idle();
      }
    });
  }
}