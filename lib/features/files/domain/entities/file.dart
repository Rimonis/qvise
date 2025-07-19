// lib/features/files/domain/entities/file.dart

enum FileType {
  image,
  pdf,
  document,
  other,
}

class FileEntity {
  final String id;
  final String userId;
  final String lessonId;
  final String name;
  final String filePath;
  final FileType fileType;
  final int fileSize;
  final String? remoteUrl;
  final bool isStarred;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  const FileEntity({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.name,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.remoteUrl,
    required this.isStarred,
    required this.createdAt,
    this.updatedAt,
    required this.syncStatus,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileEntity &&
        other.id == id &&
        other.userId == userId &&
        other.lessonId == lessonId &&
        other.name == name &&
        other.filePath == filePath &&
        other.fileType == fileType &&
        other.fileSize == fileSize &&
        other.remoteUrl == remoteUrl &&
        other.isStarred == isStarred &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      lessonId,
      name,
      filePath,
      fileType,
      fileSize,
      remoteUrl,
      isStarred,
      createdAt,
      updatedAt,
      syncStatus,
    );
  }

  @override
  String toString() {
    return 'FileEntity(id: $id, name: $name, fileType: $fileType, isStarred: $isStarred)';
  }
}