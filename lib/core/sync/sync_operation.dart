// lib/core/sync/sync_operation.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';

enum OperationType { create, update, delete }

class SyncOperation {
  final String id;
  final String entityId;
  final String entityType;
  final OperationType operationType;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final int attempts;

  SyncOperation({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.operationType,
    this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  factory SyncOperation.create({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> payload,
  }) {
    return SyncOperation(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      operationType: OperationType.create,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  factory SyncOperation.update({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> payload,
  }) {
    return SyncOperation(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      operationType: OperationType.update,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  factory SyncOperation.delete({
    required String entityId,
    required String entityType,
  }) {
    return SyncOperation(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      operationType: OperationType.delete,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType,
      'operationType': operationType.name,
      'payload': payload != null ? jsonEncode(payload) : null,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'attempts': attempts,
    };
  }

  factory SyncOperation.fromDatabase(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as String,
      entityId: map['entityId'] as String,
      entityType: map['entityType'] as String, // Fixed: was just 'map as String'
      operationType: OperationType.values.byName(map['operationType'] as String), // Fixed: was just 'map as String'
      payload: map['payload'] != null ? jsonDecode(map['payload'] as String) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      attempts: map['attempts'] as int,
    );
  }

  SyncOperation copyWith({
    String? id,
    String? entityId,
    String? entityType,
    OperationType? operationType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attempts,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  String toString() {
    return 'SyncOperation(id: $id, entityId: $entityId, entityType: $entityType, operationType: $operationType, attempts: $attempts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncOperation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
