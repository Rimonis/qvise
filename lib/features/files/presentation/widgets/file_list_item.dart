// lib/features/files/presentation/widgets/file_list_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/file.dart';
import '../providers/file_providers.dart';

class FileListItem extends ConsumerWidget {
  final FileEntity file;
  final VoidCallback? onDeleted;
  final bool allowEditing;

  const FileListItem({
    super.key,
    required this.file,
    this.onDeleted,
    this.allowEditing = false,
  });

  IconData _getIconForFileType(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.document:
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorForFileType(FileType type) {
    switch (type) {
      case FileType.image:
        return Colors.green;
      case FileType.pdf:
        return Colors.red;
      case FileType.document:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSyncIcon(String status) {
    switch (status) {
      case 'queued':
      case 'uploading':
        return const SizedBox(
          width: 16, 
          height: 16, 
          child: CircularProgressIndicator(strokeWidth: 2.0),
        );
      case 'synced':
        return const Icon(Icons.cloud_done, size: 16, color: Colors.green);
      case 'failed':
        return const Icon(Icons.error, size: 16, color: Colors.red);
      default: // local_only or other
        return const Icon(Icons.cloud_off, size: 16, color: Colors.grey);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(lessonFilesProvider(file.lessonId).notifier).deleteFile(file.id);
              onDeleted?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: InkWell(
        onTap: () => OpenFile.open(file.filePath),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // File icon or image preview
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getColorForFileType(file.fileType).withValues(alpha: 0.1),
                ),
                child: file.fileType == FileType.image
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.filePath),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _getIconForFileType(file.fileType),
                            size: 24,
                            color: _getColorForFileType(file.fileType),
                          ),
                        ),
                      )
                    : Icon(
                        _getIconForFileType(file.fileType),
                        size: 24,
                        color: _getColorForFileType(file.fileType),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _buildSyncIcon(file.syncStatus),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatFileSize(file.fileSize),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              if (allowEditing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        file.isStarred ? Icons.star : Icons.star_border,
                        color: file.isStarred ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        ref
                            .read(lessonFilesProvider(file.lessonId).notifier)
                            .toggleStar(file.id, file.isStarred);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _showDeleteConfirmation(context, ref),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
