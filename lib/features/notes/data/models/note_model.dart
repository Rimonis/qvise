// lib/features/notes/data/models/note_model.dart

import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/note.dart';

part 'note_model.freezed.dart';
part 'note_model.g.dart';

@freezed
class NoteModel with _$NoteModel {
  const factory NoteModel({
    required String id,
    required String lessonId,
    required String userId,
    String? title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('pending') String syncStatus,
    @Default(1) int version,
  }) = _NoteModel;

  const NoteModel._();

  factory NoteModel.fromJson(Map<String, dynamic> json) =>
      _$NoteModelFromJson(json);

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      lessonId: note.lessonId,
      userId: note.userId,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt ?? DateTime.now(),
      syncStatus: note.syncStatus,
      version: 1,
    );
  }

  Note toEntity() {
    return Note(
      id: id,
      lessonId: lessonId,
      userId: userId,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
    );
  }

  // SQLite serialization methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'version': version,
      'is_deleted': 0,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      lessonId: map['lesson_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String?,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      version: map['version'] as int? ?? 1,
    );
  }
}