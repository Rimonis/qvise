// lib/features/notes/domain/entities/note.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String lessonId,
    required String userId,
    String? title,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default('pending') String syncStatus,
  }) = _Note;

  const Note._();

  bool get isEmpty => content.trim().isEmpty;
  bool get hasTitle => title != null && title!.trim().isNotEmpty;
  
  DateTime get lastModified => updatedAt ?? createdAt;
  
  String get displayTitle {
    if (hasTitle) return title!;
    // Extract first line or first 50 characters as title
    final lines = content.trim().split('\n');
    final firstLine = lines.first.trim();
    if (firstLine.length <= 50) return firstLine;
    return '${firstLine.substring(0, 47)}...';
  }
  
  String get preview {
    final cleanContent = content.trim();
    if (cleanContent.length <= 100) return cleanContent;
    return '${cleanContent.substring(0, 97)}...';
  }
}