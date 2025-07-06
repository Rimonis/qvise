// lib/core/application/sync_coordinator.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/application/sync_state.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';

final syncCoordinatorProvider = StateNotifierProvider<SyncCoordinator, SyncState>((ref) {
  return SyncCoordinator(ref);
});

class SyncCoordinator extends StateNotifier<SyncState> {
  final Ref _ref;
  bool _isSyncing = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  SyncCoordinator(this._ref) : super(const SyncState.idle());

  Future<void> syncAll() async {
    if (_isSyncing) return;

    _isSyncing = true;
    state = const SyncState.syncing();
    if (kDebugMode) {
      print('🔄 SyncCoordinator: Starting sync...');
    }

    try {
      // For now, we only sync flashcards. This can be expanded later.
      await _syncFlashcards();

      state = const SyncState.success();
      await Future.delayed(const Duration(seconds: 2)); // Keep success state for a moment
      state = const SyncState.idle();
      _retryCount = 0; // Reset retry count on success
       if (kDebugMode) {
        print('✅ SyncCoordinator: Sync completed successfully.');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ SyncCoordinator: Sync failed. Error: $e');
      }
      _handleSyncError(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncFlashcards() async {
    final repository = _ref.read(flashcardRepositoryProvider);
    final pendingFlashcardsResult = await repository.getPendingSyncFlashcards();

    await pendingFlashcardsResult.fold(
      (failure) => throw Exception('Failed to get pending cards: ${failure.message}'),
      (pendingCards) async {
        if (pendingCards.isNotEmpty) {
           if (kDebugMode) {
            print('🔄 SyncCoordinator: Found ${pendingCards.length} pending flashcards to sync.');
          }
          final idsToSync = pendingCards.map((card) => card.id).toList();
          final syncResult = await repository.syncFlashcardsToRemote(idsToSync);
          syncResult.fold(
            (failure) => throw Exception('Failed to sync cards to remote: ${failure.message}'),
            (_) => null,
          );
        } else {
           if (kDebugMode) {
            print('👍 SyncCoordinator: No pending flashcards to sync.');
          }
        }
      },
    );
  }

  void _handleSyncError(String error) {
    _retryCount++;
    if (_retryCount <= _maxRetries) {
      final delay = Duration(seconds: (5 * _retryCount)); // Exponential backoff
      if (kDebugMode) {
        print('🔁 SyncCoordinator: Retrying sync in ${delay.inSeconds} seconds...');
      }
      Future.delayed(delay, syncAll);
      state = SyncState.error('Sync failed. Retrying... ($_retryCount/$_maxRetries)');
    } else {
      if (kDebugMode) {
        print('🚫 SyncCoordinator: Max retries reached. Sync failed.');
      }
      state = SyncState.error('Sync failed after $_maxRetries attempts.');
      // Keep error state for a while before going idle
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && state is Error) {
          state = const SyncState.idle();
        }
      });
    }
  }
}