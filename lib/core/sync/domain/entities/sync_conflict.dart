// lib/core/sync/domain/entities/sync_conflict.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_conflict.freezed.dart';
part 'sync_conflict.g.dart';

@freezed
class SyncConflict with _$SyncConflict {
  const factory SyncConflict({
    required String id,
    required String entityType, // 'lesson', 'flashcard', 'subject', 'topic'
    required String entityId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required int localVersion,
    required int remoteVersion,
    required DateTime localUpdatedAt,
    required DateTime remoteUpdatedAt,
    required DateTime detectedAt,
    DateTime? resolvedAt,
    @Default('unresolved') String status,
    String? resolutionType,
    String? resolvedBy,
    Map<String, dynamic>? metadata,
  }) = _SyncConflict;

  factory SyncConflict.fromJson(Map<String, dynamic> json) =>
      _$SyncConflictFromJson(json);
}

enum ConflictStatus {
  unresolved,
  resolvedLocalWins,
  resolvedRemoteWins,
  resolvedMerged,
  resolvedManual,
}
