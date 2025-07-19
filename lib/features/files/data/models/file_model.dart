// lib/features/files/data/models/file_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/file.dart';

part 'file_model.freezed.dart';
part 'file_model.g.dart';

@freezed
class FileModel with _$FileModel {
  const FileModel._();

  const factory FileModel({
    required String id,
    required String userId,
    required String lessonId,
    required String name,
    required String filePath,
    required String fileType,
    required int fileSize,
    String? remoteUrl,
    required int isStarred,
    required int createdAt,
    int? updatedAt,
    required String syncStatus,
    required int version,
  }) = _FileModel;

  factory FileModel.fromJson(Map<String, dynamic> json) =>
      _$FileModelFromJson(json);

  factory FileModel.fromDb(Map<String, dynamic> dbMap) {
    return FileModel(
      id: dbMap['id'],
      userId: dbMap['user_id'],
      lessonId: dbMap['lesson_id'],
      name: dbMap['name'],
      filePath: dbMap['file_path'],
      fileType: dbMap['file_type'],
      fileSize: dbMap['file_size'],
      remoteUrl: dbMap['remote_url'],
      isStarred: dbMap['is_starred'],
      createdAt: dbMap['created_at'],
      updatedAt: dbMap['updated_at'],
      syncStatus: dbMap['sync_status'],
      version: dbMap['version'],
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'name': name,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'remote_url': remoteUrl,
      'is_starred': isStarred,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'version': version,
    };
  }

  FileEntity toEntity() {
    return FileEntity(
      id: id,
      userId: userId,
      lessonId: lessonId,
      name: name,
      filePath: filePath,
      fileType: _fileTypeFromString(fileType),
      fileSize: fileSize,
      remoteUrl: remoteUrl,
      isStarred: isStarred == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
          : null,
      syncStatus: syncStatus,
    );
  }

  static FileType _fileTypeFromString(String type) {
    switch (type) {
      case 'image':
        return FileType.image;
      case 'pdf':
        return FileType.pdf;
      case 'document':
        return FileType.document;
      default:
        return FileType.other;
    }
  }
}