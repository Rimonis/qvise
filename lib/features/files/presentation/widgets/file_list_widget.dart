// lib/features/files/presentation/widgets/file_list_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/file.dart';
import '../providers/file_providers.dart';
import '../screens/file_viewer_screen.dart';
import 'file_item_widget.dart';

class FileListWidget extends ConsumerWidget {
  final String lessonId;
  final bool allowEditing;

  const FileListWidget({
    super.key,
    required this.lessonId,
    this.allowEditing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(lessonFilesProvider(lessonId));

    return filesAsync.when(
      data: (files) => _buildFilesList(context, ref, files),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildFilesList(BuildContext context, WidgetRef ref, List<FileEntity> files) {
    if (files.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: FileItemWidget(
            file: file,
            onTap: () => _openFile(context, file),
            onStarToggle: allowEditing
                ? () => _toggleStar(context, ref, file)
                : null,
            onDelete: allowEditing
                ? () => _deleteFile(context, ref, file)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No files yet',
            style: context.textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            allowEditing
                ? 'Add files to enhance your lesson content'
                : 'No files have been added to this lesson',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load files',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(BuildContext context, FileEntity file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileViewerScreen(file: file),
      ),
    );
  }

  Future<void> _toggleStar(BuildContext context, WidgetRef ref, FileEntity file) async {
    try {
      final lessonFilesNotifier = ref.read(lessonFilesProvider(lessonId).notifier);
      await lessonFilesNotifier.toggleStar(file.id, file.isStarred);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(file.isStarred ? 'Removed from favorites' : 'Added to favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref, FileEntity file) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldDelete && context.mounted) {
      try {
        final lessonFilesNotifier = ref.read(lessonFilesProvider(lessonId).notifier);
        await lessonFilesNotifier.deleteFile(file.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete file: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}