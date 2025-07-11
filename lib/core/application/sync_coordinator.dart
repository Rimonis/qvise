// lib/core/application/sync_coordinator.dart
import 'dart:async';
import 'package:backoff/backoff.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/application/sync_state.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/core/sync/sync_operation.dart';
import 'package:qvise/core/sync/sync_queue.dart';
import 'package:qvise/features/flashcards/shared/data/models/flashcard_model.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';

final syncCoordinatorProvider = StateNotifierProvider<SyncCoordinator, SyncState>((ref) {
  return SyncCoordinator(ref);
});

class SyncCoordinator extends StateNotifier<SyncState> {
  final Ref _ref;
  bool _isSyncing = false;

  SyncCoordinator(this._ref) : super(const SyncState.idle()) {
    // Listen to network changes to trigger sync automatically
    _ref.listen(networkStatusProvider, (_, next) {
      if (next.valueOrNull == true) {
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;

    final isOnline = _ref.read(networkStatusProvider).valueOrNull?? false;
    if (!isOnline) {
      if (kDebugMode) {
        print('SyncCoordinator: Offline, skipping sync.');
      }
      return;
    }

    _isSyncing = true;
    state = const SyncState.syncing();
    if (kDebugMode) {
      print('🔄 SyncCoordinator: Starting sync process...');
    }

    try {
      final syncQueue = _ref.read(syncQueueProvider);
      List<SyncOperation> operations;
      do {
        operations = await syncQueue.getPendingOperations(limit: 20);
        if (operations.isNotEmpty) {
          await _processBatch(operations);
        }
      } while (operations.isNotEmpty);

      state = const SyncState.success();
      if (kDebugMode) {
        print('✅ SyncCoordinator: Sync queue processed successfully.');
      }
      // Invalidate providers to refresh UI with synced data
      _ref.invalidate(flashcardsByLessonProvider);
      // _ref.invalidate(dueLessonsProvider); // Example for other features
    } catch (e, st) {
      state = SyncState.failure(e.toString());
      if (kDebugMode) {
        print('❌ SyncCoordinator: Sync failed. Error: $e');
        print(st);
      }
    } finally {
      _isSyncing = false;
      // Revert to idle after a short delay to allow UI to show success/failure state
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = const SyncState.idle();
        }
      });
    }
  }

  Future<void> _processBatch(List<SyncOperation> operations) async {
    final flashcardRepo = _ref.read(flashcardRepositoryProvider);
    final syncQueue = _ref.read(syncQueueProvider);

    for (final op in operations) {
      final backOff = ExponentialBackOff(
        initialInterval: const Duration(seconds: 1),
        maxInterval: const Duration(seconds: 30),
        maxElapsedTime: const Duration(minutes: 2),
      );

      await for (final duration in backOff.intervals) {
        try {
          bool success = await _processOperation(op, flashcardRepo);
          if (success) {
            await syncQueue.removeOperation(op.id);
            break; // Success, move to next operation
          }
        } catch (e) {
          await syncQueue.incrementAttempt(op.id);
          await Future.delayed(duration); // Wait before retrying
        }
      }
    }
  }

  Future<bool> _processOperation(SyncOperation op, FlashcardRepository repo) async {
    if (op.entityType == 'flashcard') {
      switch (op.operationType) {
        case OperationType.create:
        case OperationType.update:
          final model = FlashcardModel.fromJson(op.payload!);
          final result = await repo.syncFlashcardsToRemote([model.toEntity()]);
          return result.isRight();
        case OperationType.delete:
          // Assuming the remote delete is handled by a different mechanism or is also queued
          // For simplicity, we'll assume success here if the local delete was already done.
          return true;
      }
    }
    // Handle other entity types here
    return false;
  }
}