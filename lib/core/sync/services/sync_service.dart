// lib/core/sync/services/sync_service.dart

import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/data/datasources/content_remote_data_source.dart';
import 'package:qvise/features/content/data/models/lesson_model.dart';
import 'package:qvise/features/content/data/models/subject_model.dart';
import 'package:qvise/features/content/data/models/topic_model.dart';
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
  final DeviceInfoPlugin _deviceInfo;

  bool _isSyncing = false;
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const int _pushBatchSize = 50;

  SyncService({
    required IUnitOfWork unitOfWork,
    required ContentRemoteDataSource remoteContent,
    required FlashcardRemoteDataSource remoteFlashcard,
    required ConflictLocalDataSource conflictDataSource,
    required SharedPreferences prefs,
    required String userId,
    RemoteEntityCache? cache,
    DeviceInfoPlugin? deviceInfo,
  })  : _unitOfWork = unitOfWork,
        _remoteContent = remoteContent,
        _remoteFlashcard = remoteFlashcard,
        _conflictDataSource = conflictDataSource,
        _prefs = prefs,
        _userId = userId,
        _cache = cache ?? RemoteEntityCache(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

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

      // 1. Detect conflicts in parallel
      final conflicts = await perfMonitor.measureOperation(
        'detect-all-conflicts',
        () => _detectAllConflictsParallel(lastSync),
      );
      report.conflictsDetected = conflicts.length;

      // 2. Save conflicts
      if (conflicts.isNotEmpty) {
        await perfMonitor.measureOperation(
          'save-conflicts',
          () => _saveConflicts(conflicts),
        );
      }

      // 3. Push and pull changes in parallel
      final pushPullResults = await perfMonitor.measureOperation(
        'push-pull-changes',
        () => Future.wait([
          _pushLocalChanges(lastSync),
          _pullRemoteChanges(lastSync),
        ]),
      );
      report.itemsPushed = pushPullResults[0];
      report.itemsPulled = pushPullResults[1];

      // 4. Update sync timestamp
      await _updateLastSyncTime();

      // 5. Finalize report
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
    final conflicts = <SyncConflict>[];
    try {
      final localLessons =
          await _unitOfWork.content.getModifiedSince(lastSync);
      if (localLessons.isEmpty) return conflicts;

      final lessonIds = localLessons.map((l) => l.id).toList();
      final remoteLessons = await BatchHelpers.batchProcess<String, LessonModel>(
        items: lessonIds,
        processBatch: (batch) => _remoteContent.getLessonsByIds(batch),
        continueOnError: true,
      );

      final remoteMap = {for (var lesson in remoteLessons) lesson.id: lesson};
      _cache.putAll(remoteMap.map((id, lesson) => MapEntry(id, lesson)));

      for (final local in localLessons) {
        final remote = remoteMap[local.id];
        if (remote != null && _isConflict(local, remote, lastSync)) {
          conflicts.add(await _createLessonConflict(local, remote));
        }
      }
    } catch (e) {
      print('Error detecting lesson conflicts: $e');
    }
    return conflicts;
  }

    Future<List<SyncConflict>> _detectFlashcardConflicts(DateTime lastSync) async {
    final conflicts = <SyncConflict>[];
    try {
      final localFlashcards =
          await _unitOfWork.flashcard.getModifiedSince(lastSync);
      if (localFlashcards.isEmpty) return conflicts;

      final flashcardIds = localFlashcards.map((f) => f.id).toList();
      final remoteFlashcards =
          await BatchHelpers.batchProcess<String, FlashcardModel>(
        items: flashcardIds,
        processBatch: (batch) => _remoteFlashcard.getFlashcardsByIds(batch),
      );

      final remoteMap = {for (var f in remoteFlashcards) f.id: f};

      for (final local in localFlashcards) {
        final remote = remoteMap[local.id];
        if (remote != null && _isConflict(local, remote, lastSync)) {
          conflicts.add(await _createFlashcardConflict(local, remote));
        }
      }
    } catch (e) {
      print('Error detecting flashcard conflicts: $e');
    }
    return conflicts;
  }

  Future<int> _pushLocalChanges(DateTime lastSync) async {
    final pushFutures = <Future<int>>[
      _pushLessons(),
      _pushFlashcards(),
    ];
    final results = await Future.wait(pushFutures);
    return results.reduce((a, b) => a + b);
  }

  Future<int> _pushLessons() async {
    try {
      final unpushedLessons = await _unitOfWork.content.getUnpushedChanges();
      if (unpushedLessons.isEmpty) return 0;

      await _remoteContent.batchUpdateLessons(unpushedLessons);
      await _unitOfWork.transaction(() async {
        for (final lesson in unpushedLessons) {
          await _unitOfWork.content.markAsSynced(lesson.id);
        }
      });
      return unpushedLessons.length;
    } catch (e) {
      print('Error pushing lessons: $e');
      return 0;
    }
  }

  Future<int> _pushFlashcards() async {
    try {
      final unpushedFlashcards =
          await _unitOfWork.flashcard.getUnpushedChanges();
      if (unpushedFlashcards.isEmpty) return 0;

      await _remoteFlashcard.batchUpdateFlashcards(unpushedFlashcards);
      await _unitOfWork.transaction(() async {
        for (final flashcard in unpushedFlashcards) {
          await _unitOfWork.flashcard.markAsSynced(flashcard.id);
        }
      });
      return unpushedFlashcards.length;
    } catch (e) {
      print('Error pushing flashcards: $e');
      return 0;
    }
  }

  Future<int> _pullRemoteChanges(DateTime lastSync) async {
    final pullFutures = <Future<int>>[
      _pullLessons(lastSync),
      _pullFlashcards(lastSync),
    ];
    final results = await Future.wait(pullFutures);
    return results.reduce((a, b) => a + b);
  }

  Future<int> _pullLessons(DateTime lastSync) async {
    try {
      final remoteLessons =
          await _remoteContent.getLessonsModifiedSince(lastSync, _userId);
      if (remoteLessons.isEmpty) return 0;

      final conflicts = await _conflictDataSource.getUnresolvedConflicts();
      final conflictedIds = conflicts
          .where((c) => c.entityType == 'lesson')
          .map((c) => c.entityId)
          .toSet();

      int pulled = 0;
      await _unitOfWork.transaction(() async {
        for (final remote in remoteLessons) {
          if (conflictedIds.contains(remote.id)) continue;
          final local = await _unitOfWork.content.getLesson(remote.id);
          if (local == null || local.version < remote.version) {
            await _unitOfWork.content.insertOrUpdateLesson(remote);
            pulled++;
          }
        }
      });
      return pulled;
    } catch (e) {
      print('Error pulling lessons: $e');
      return 0;
    }
  }

  Future<int> _pullFlashcards(DateTime lastSync) async {
    try {
      final remoteFlashcards =
          await _remoteFlashcard.getFlashcardsModifiedSince(lastSync, _userId);
      if (remoteFlashcards.isEmpty) return 0;

      final conflicts = await _conflictDataSource.getUnresolvedConflicts();
      final conflictedIds = conflicts
          .where((c) => c.entityType == 'flashcard')
          .map((c) => c.entityId)
          .toSet();

      int pulled = 0;
      await _unitOfWork.transaction(() async {
        for (final remote in remoteFlashcards) {
          if (conflictedIds.contains(remote.id)) continue;
          final local = await _unitOfWork.flashcard.getFlashcard(remote.id);
          if (local == null || local.version < remote.version) {
            await _unitOfWork.flashcard.updateFlashcard(remote);
            pulled++;
          }
        }
      });
      return pulled;
    } catch (e) {
      print('Error pulling flashcards: $e');
      return 0;
    }
  }

  Future<SyncConflict> _createLessonConflict(
      LessonModel local, LessonModel remote) async {
    return SyncConflict(
      id: const Uuid().v4(),
      entityType: 'lesson',
      entityId: local.id,
      localData: local.toJson(),
      remoteData: remote.toJson(),
      localVersion: local.version,
      remoteVersion: remote.version,
      localUpdatedAt: local.updatedAt,
      remoteUpdatedAt: remote.updatedAt,
      detectedAt: DateTime.now(),
      metadata: {
        'userId': _userId,
        'deviceId': await _getDeviceId(),
      },
    );
  }

  Future<SyncConflict> _createFlashcardConflict(
      FlashcardModel local, FlashcardModel remote) async {
    return SyncConflict(
      id: const Uuid().v4(),
      entityType: 'flashcard',
      entityId: local.id,
      localData: local.toMap(),
      remoteData: remote.toMap(),
      localVersion: local.version,
      remoteVersion: remote.version,
      localUpdatedAt: local.updatedAt,
      remoteUpdatedAt: remote.updatedAt,
      detectedAt: DateTime.now(),
      metadata: {
        'userId': _userId,
        'deviceId': await _getDeviceId(),
        'lessonId': local.lessonId,
      },
    );
  }

  Future<void> _saveConflicts(List<SyncConflict> conflicts) async {
    await _unitOfWork.transaction(() async {
      for (final conflict in conflicts) {
        await _conflictDataSource.saveConflict(conflict);
      }
    });
  }

  bool _isConflict(dynamic local, dynamic remote, DateTime lastSync) {
    return local.updatedAt.isAfter(lastSync) &&
        remote.updatedAt.isAfter(lastSync) &&
        local.version == remote.version;
  }

  DateTime _getLastSyncTime() {
    final timestamp = _prefs.getInt(_lastSyncKey) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> _updateLastSyncTime() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios-unknown';
      }
    } catch (e) {
      // Fallback for other platforms or errors
    }
    return 'unknown-device';
  }
}