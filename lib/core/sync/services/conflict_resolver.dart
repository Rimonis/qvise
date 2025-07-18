// lib/core/sync/services/conflict_resolver.dart
import 'dart:math';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/core/sync/data/datasources/conflict_local_datasource.dart';
import '../domain/entities/sync_conflict.dart';

enum ConflictResolutionStrategy { localWins, remoteWins }
enum ResolutionType { localWins, remoteWins, merge }

class ConflictResolution {
  final ResolutionType type;
  final Map<String, dynamic>? mergedData;

  ConflictResolution(this.type, {this.mergedData});
}

class ConflictResolver {
  final ConflictResolutionStrategy defaultStrategy;
  final ConflictLocalDataSource _conflictDataSource;

  ConflictResolver({
    this.defaultStrategy = ConflictResolutionStrategy.remoteWins,
    required IUnitOfWork unitOfWork,
    required ConflictLocalDataSource conflictDataSource,
  }) : _conflictDataSource = conflictDataSource;

  Future<void> resolveConflict(
    SyncConflict conflict,
    ConflictResolution resolution,
  ) async {
    // Placeholder for actual resolution logic
    await _markConflictResolved(conflict.id, resolution.type.toString());
  }

  Future<Map<String, dynamic>?> suggestSmartMerge(SyncConflict conflict) async {
    final local = conflict.localData;
    final remote = conflict.remoteData;
    final merged = <String, dynamic>{};

    for (final key in {...local.keys, ...remote.keys}) {
      if (local[key] == remote[key]) {
        merged[key] = local[key];
      } else {
        merged[key] = _mergeField(key, local[key], remote[key]);
      }
    }

    merged['version'] = max(local['version'] as int, remote['version'] as int) + 1;
    merged['updated_at'] = DateTime.now().toIso8601String();

    return merged;
  }

  dynamic _mergeField(
      String fieldName, dynamic localValue, dynamic remoteValue) {
    switch (fieldName) {
      case 'flashcard_count':
      case 'note_count':
      case 'file_count':
        return max(localValue as int, remoteValue as int);
      case 'proficiency':
        return ((localValue as double) + (remoteValue as double)) / 2;
      case 'last_reviewed_at':
      case 'last_studied':
        final localDate = DateTime.parse(localValue as String);
        final remoteDate = DateTime.parse(remoteValue as String);
        return localDate.isAfter(remoteDate) ? localValue : remoteValue;
      case 'review_count':
      case 'correct_count':
        return (localValue as int) + (remoteValue as int);
      default:
        return remoteValue;
    }
  }

  Future<void> _markConflictResolved(String id, String resolutionType) async {
    await _conflictDataSource.resolveConflict(id, resolutionType);
  }
}