// lib/core/sync/services/sync_service.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/data/datasources/content_remote_data_source.dart';
import 'package:qvise/features/content/data/models/lesson_model.dart';
import 'package:qvise/features/flashcards/shared/data/datasources/flashcard_remote_data_source.dart';
import 'package:qvise/features/flashcards/shared/data/models/flashcard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/datasources/conflict_local_datasource.dart';
import '../domain/entities/sync_conflict.dart';
import '../domain/entities/sync_report.dart';
import '../utils/batch_helpers.dart';
import 'remote_entity_cache.dart';
import 'sync_performance_monitor.dart';

class SyncService {
  final IUnitOfWork _unitOfWork;
  final ContentRemoteDataSource _remoteContent;
  final FlashcardRemoteDataSource _remoteFlashcard;
  final ConflictLocalDataSource _conflictDataSource;
  final SharedPreferences _prefs;
  final String _userId;
  final RemoteEntityCache _cache;

  bool _isSyncing = false;
  static const String _lastSyncKey = 'last_sync_timestamp';

  SyncService({
    required IUnitOfWork unitOfWork,
    required ContentRemoteDataSource remoteContent,
    required FlashcardRemoteDataSource remoteFlashcard,
    required ConflictLocalDataSource conflictDataSource,
    required SharedPreferences prefs,
    required String userId,
    RemoteEntityCache? cache,
  })  : _unitOfWork = unitOfWork,
        _remoteContent = remoteContent,
        _remoteFlashcard = remoteFlashcard,
        _conflictDataSource = conflictDataSource,
        _prefs = prefs,
        _userId = userId,
        _cache = cache ?? RemoteEntityCache();

  Future<Either<AppFailure, SyncReport>> performSync() async {
    if (_isSyncing) {
      return Left(const AppFailure(
        type: FailureType.sync,
        message: 'Sync already in progress',
      ));
    }

    _isSyncing = true;
    final perfMonitor = SyncPerformanceMonitor();
    final report = SyncReport(startedAt: DateTime.now());

    try {
      final lastSync = _getLastSyncTime();
      _cache.clear();

      final conflicts = await perfMonitor.measureOperation(
        'detect-all-conflicts',
        () => _detectAllConflictsParallel(lastSync),
      );
      report.conflictsDetected = conflicts.length;

      if (conflicts.isNotEmpty) {
        await perfMonitor.measureOperation(
          'save-conflicts',
          () => _saveConflicts(conflicts),
        );
      }

      final pushPullResults = await perfMonitor.measureOperation(
        'push-pull-changes',
        () => Future.wait([
          _pushLocalChanges(lastSync),
          _pullRemoteChanges(lastSync),
        ]),
      );

      report.itemsPushed = pushPullResults[0];
      report.itemsPulled = pushPullResults[1];

      await _updateLastSyncTime();

      report.completedAt = DateTime.now();
      report.unresolvedConflicts =
          await _conflictDataSource.getUnresolvedConflicts();
      report.status = report.hasUnresolvedConflicts
          ? SyncStatus.completedWithConflicts
          : SyncStatus.completed;

      perfMonitor.logSummary();
      return Right(report);
    } catch (e, stack) {
      report.errors.add(SyncError(
        message: e.toString(),
        stackTrace: stack,
        timestamp: DateTime.now(),
      ));
      report.status = SyncStatus.failed;
      return Left(AppFailure.fromException(e, stack));
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<SyncConflict>> _detectAllConflictsParallel(
      DateTime lastSync) async {
    final conflictFutures = <Future<List<SyncConflict>>>[
      _detectLessonConflicts(lastSync),
      _detectFlashcardConflicts(lastSync),
    ];
    final conflictLists = await Future.wait(conflictFutures);
    return conflictLists.expand((list) => list).toList();
  }

  Future<List<SyncConflict>> _detectLessonConflicts(DateTime lastSync) async {
    // Placeholder for actual implementation
    return [];
  }

  Future<List<SyncConflict>> _detectFlashcardConflicts(
      DateTime lastSync) async {
    // Placeholder for actual implementation
    return [];
  }

  Future<int> _pushLocalChanges(DateTime lastSync) async {
    // Placeholder for actual implementation
    return 0;
  }

  Future<int> _pullRemoteChanges(DateTime lastSync) async {
    // Placeholder for actual implementation
    return 0;
  }

  Future<void> _saveConflicts(List<SyncConflict> conflicts) async {
    final batches = BatchHelpers.chunk(conflicts, 100);
    for (final batch in batches) {
      await _unitOfWork.transaction(() async {
        for (final conflict in batch) {
          await _conflictDataSource.saveConflict(conflict);
        }
      });
    }
  }

  DateTime _getLastSyncTime() {
    final timestamp = _prefs.getInt(_lastSyncKey) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> _updateLastSyncTime() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
}
