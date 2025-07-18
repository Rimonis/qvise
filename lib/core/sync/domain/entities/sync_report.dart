// lib/core/sync/domain/entities/sync_report.dart
import 'package:qvise/core/sync/domain/entities/sync_conflict.dart';

class SyncError {
  final String message;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  SyncError({
    required this.message,
    this.stackTrace,
    required this.timestamp,
  });
}

class SyncReport {
  final DateTime startedAt;
  DateTime? completedAt;
  int itemsPushed;
  int itemsPulled;
  int conflictsDetected;
  int conflictsResolved;
  List<SyncConflict> unresolvedConflicts;
  final List<SyncError> errors;
  SyncStatus status;

  SyncReport({
    required this.startedAt,
    this.completedAt,
    this.itemsPushed = 0,
    this.itemsPulled = 0,
    this.conflictsDetected = 0,
    this.conflictsResolved = 0,
    this.unresolvedConflicts = const [],
    this.errors = const [],
    this.status = SyncStatus.running,
  });

  bool get hasUnresolvedConflicts => unresolvedConflicts.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => status == SyncStatus.completed && !hasErrors;
}

enum SyncStatus {
  running,
  completed,
  failed,
  completedWithConflicts,
}
