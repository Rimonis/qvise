// lib/core/application/sync_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state.freezed.dart';

@freezed
class SyncState with _$SyncState {
  const factory SyncState.idle() = _Idle;
  const factory SyncState.syncing() = _Syncing;
  const factory SyncState.success() = _Success;
  const factory SyncState.error(String message) = _Error;
}