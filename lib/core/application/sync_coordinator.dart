// lib/core/application/sync_coordinator.dart

import 'dart:async';
import 'dart:math';
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
  Timer? _retryTimer;

  SyncCoordinator(this._ref) : super(const SyncState.idle()) {
    // Listen to network changes to trigger sync automatically
    _ref.listen(networkStatusProvider, (_, next) {
      if (next.valueOrNull == true && !_isSyncing) {
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
    if (_isSyncing) return;

    final isOnline = _ref.read(networkStatusProvider).valueOrNull ?? false;
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
      
      // Return to idle state after showing success
      _scheduleIdleTransition();
      
    } catch (e, st) {
      state = SyncState.error(e.toString()); // Fixed: was SyncState.failure
      if (kDebugMode) {
        print('❌ SyncCoordinator: Sync failed. Error: $e');
        print(st);
      }
      
      // Schedule a retry
      _scheduleRetry();
      
    } finally {
      _isSyncing = false;
    }
  }

  void _scheduleIdleTransition() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        state = const SyncState.idle();
      }
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        syncAll();
      }
    });
  }

  Future<void> _processBatch(List<SyncOperation> operations) async {
    final flashcardRepo = _ref.read(flashcardRepositoryProvider);
    final syncQueue = _ref.read(syncQueueProvider);

    for (final op in operations) {
      bool success = false;
      int maxAttempts = 3;
      
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          success = await _processOperation(op, flashcardRepo);
          if (success) {
            await syncQueue.removeOperation(op.id);
            break; // Success, move to next operation
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ SyncCoordinator: Operation ${op.id} failed attempt $attempt: $e');
          }
          
          if (attempt < maxAttempts) {
            await syncQueue.incrementAttempt(op.id);
            // Exponential backoff: 1s, 2s, 4s
            final delay = Duration(seconds: pow(2, attempt - 1).toInt());
            await Future.delayed(delay);
          } else {
            // Max attempts reached, remove operation to prevent infinite retries
            await syncQueue.removeOperation(op.id);
            if (kDebugMode) {
              print('❌ SyncCoordinator: Operation ${op.id} failed permanently after $maxAttempts attempts');
            }
          }
        }
      }
    }
  }

  Future<bool> _processOperation(SyncOperation op, FlashcardRepository repo) async {
    if (op.entityType == 'flashcard') {
      switch (op.operationType) {
        case OperationType.create:
        case OperationType.update:
          if (op.payload == null) {
            if (kDebugMode) {
              print('❌ SyncCoordinator: No payload for ${op.operationType} operation');
            }
            return false;
          }
          
          final model = FlashcardModel.fromJson(op.payload!);
          final result = await repo.syncFlashcardsToRemote([model.toEntity()]);
          return result.fold(
            (error) {
              if (kDebugMode) {
                print('❌ SyncCoordinator: Flashcard sync failed: ${error.message}');
              }
              return false;
            },
            (_) => true,
          );
          
        case OperationType.delete:
          // For delete operations, we assume they're already processed locally
          // and we just need to mark them as synced
          return true;
      }
    }
    
    // Handle other entity types here (lessons, etc.)
    if (kDebugMode) {
      print('⚠️ SyncCoordinator: Unknown entity type: ${op.entityType}');
    }
    return false;
  }

  /// Force sync regardless of network status (for manual sync)
  Future<void> forceSyncAll() async {
    await syncAll();
  }

  /// Get current sync status
  bool get isSyncing => _isSyncing;
}
