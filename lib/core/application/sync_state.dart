// lib/core/application/sync_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/core/sync/domain/entities/sync_conflict.dart';
import 'package:qvise/core/sync/domain/entities/sync_report.dart';

part 'sync_state.freezed.dart';

@freezed
class SyncState with _$SyncState {
  const factory SyncState.idle() = _Idle;
  const factory SyncState.syncing() = _Syncing;
  const factory SyncState.success(SyncReport report) = _Success;
  const factory SyncState.error(AppFailure failure) = _Error;
  const factory SyncState.hasConflicts(List<SyncConflict> conflicts) =
      _HasConflicts;
}
