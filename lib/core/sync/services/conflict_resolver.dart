// lib/core/sync/services/conflict_resolver.dart
import 'dart:math';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/core/sync/data/datasources/conflict_local_datasource.dart';
import 'package:qvise/features/content/data/models/lesson_model.dart';
import 'package:qvise/features/flashcards/shared/data/models/flashcard_model.dart';
import '../domain/entities/sync_conflict.dart';

enum ConflictResolutionStrategy { localWins, remoteWins, smartMerge }
enum ResolutionType { localWins, remoteWins, merge, autoMerge }

class ConflictResolution {
  final ResolutionType type;
  final Map<String, dynamic>? mergedData;

  ConflictResolution(this.type, {this.mergedData});
}

class ConflictResolver {
  final ConflictResolutionStrategy defaultStrategy;
  final ConflictLocalDataSource _conflictDataSource;
  final IUnitOfWork _unitOfWork;

  ConflictResolver({
    this.defaultStrategy = ConflictResolutionStrategy.smartMerge,
    required IUnitOfWork unitOfWork,
    required ConflictLocalDataSource conflictDataSource,
  })  : _unitOfWork = unitOfWork,
        _conflictDataSource = conflictDataSource;

  Future<int> autoResolveConflicts() async {
    final unresolved = await _conflictDataSource.getUnresolvedConflicts();
    int resolvedCount = 0;
    for (final conflict in unresolved) {
      final mergedData = await suggestSmartMerge(conflict);
      if (mergedData != null) {
        // Apply the merge and resolve the conflict
        await _applyMerge(conflict, mergedData);
        await _markConflictResolved(conflict.id, ResolutionType.autoMerge.toString());
        resolvedCount++;
      }
    }
    return resolvedCount;
  }

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
        merged[key] = _mergeField(key, local[key], remote[key], local, remote);
      }
    }

    merged['version'] = max(local['version'] as int, remote['version'] as int) + 1;
    merged['updated_at'] = DateTime.now().toIso8601String();
    merged['sync_status'] = 'synced';

    return merged;
  }

  dynamic _mergeField(String fieldName, dynamic localValue, dynamic remoteValue, Map<String, dynamic> local, Map<String, dynamic> remote) {
    switch (fieldName) {
      // Numerical fields: prefer the higher value
      case 'flashcard_count':
      case 'note_count':
      case 'file_count':
      case 'review_count':
      case 'correct_count':
        return max(localValue as int? ?? 0, remoteValue as int? ?? 0);

      // Proficiency: average them
      case 'proficiency':
        return ((localValue as double? ?? 0.0) + (remoteValue as double? ?? 0.0)) / 2;

      // Timestamps: prefer the more recent one
      case 'last_reviewed_at':
      case 'last_studied':
        final localDate = localValue != null ? DateTime.tryParse(localValue as String) : null;
        final remoteDate = remoteValue != null ? DateTime.tryParse(remoteValue as String) : null;
        if (localDate == null) return remoteValue;
        if (remoteDate == null) return localValue;
        return localDate.isAfter(remoteDate) ? localValue : remoteValue;
      
      // Boolean fields: prefer 'true'
      case 'is_favorite':
      case 'is_locked':
        return (localValue as bool? ?? false) || (remoteValue as bool? ?? false);

      // List fields: merge and deduplicate
      case 'hints':
        final localList = List<String>.from(localValue as List? ?? []);
        final remoteList = List<String>.from(remoteValue as List? ?? []);
        return {...localList, ...remoteList}.toList();
      
      // Text fields: prefer the longer, more descriptive text, or non-empty
      case 'notes':
      case 'front_content':
      case 'back_content':
        final localText = localValue as String? ?? '';
        final remoteText = remoteValue as String? ?? '';
        if (localText.isEmpty) return remoteText;
        if (remoteText.isEmpty) return localText;
        return localText.length > remoteText.length ? localText : remoteText;
        
      default:
        // Default to remote value for other fields
        return remoteValue;
    }
  }

  Future<void> _applyMerge(SyncConflict conflict, Map<String, dynamic> mergedData) async {
    await _unitOfWork.transaction(() async {
      if (conflict.entityType == 'flashcard') {
        final flashcard = FlashcardModel.fromMap(mergedData);
        await _unitOfWork.flashcard.updateFlashcard(flashcard);
      } else if (conflict.entityType == 'lesson') {
        final lesson = LessonModel.fromDatabase(mergedData);
        await _unitOfWork.content.insertOrUpdateLesson(lesson);
      }
      // Add other entity types as needed
    });
  }

  Future<void> _markConflictResolved(String id, String resolutionType) async {
    await _conflictDataSource.resolveConflict(id, resolutionType);
  }
}