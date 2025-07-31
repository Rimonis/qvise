// lib/features/files/presentation/widgets/file_list_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/features/files/presentation/widgets/file_list_item.dart';

import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class FileListWidget extends ConsumerWidget {
  final String lessonId;
  final bool allowEditing; // ADD THIS PARAMETER

  const FileListWidget({
    super.key,
    required this.lessonId,
    this.allowEditing = true, // DEFAULT TO TRUE FOR BACKWARD COMPATIBILITY
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(lessonFilesProvider(lessonId));

    return filesAsync.when(
      data: (files) {
        if (files.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        return Column(
          children: [
            // Add file button - ONLY SHOW IF EDITING IS ALLOWED
            if (allowEditing)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddFileOptions(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add File'),
                  ),
                ),
              ),
            
            // Files list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(lessonFilesProvider(lessonId));
                },
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return FileListItem(
                      file: file,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('Error loading files: $error'),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(lessonFilesProvider(lessonId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_file,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Files Yet',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              allowEditing 
                  ? 'Add files to enhance your lesson content'
                  : 'No files have been added to this lesson', // DIFFERENT MESSAGE FOR STUDY MODE
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // ONLY SHOW ADD BUTTON IF EDITING IS ALLOWED
            if (allowEditing)
              ElevatedButton.icon(
                onPressed: () => _showAddFileOptions(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add File'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddFileOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload from Device'),
              onTap: () {
                Navigator.pop(context);
                _uploadFromDevice(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _uploadFromDevice(BuildContext context, WidgetRef ref) async {
    try {
      final filePickerService = ref.read(filePickerServiceProvider);
      final filePaths = await filePickerService.pickMultipleFiles(FileSource.files);
      
      if (filePaths.isNotEmpty) {
        final lessonFilesNotifier = ref.read(lessonFilesProvider(lessonId).notifier);
        
        for (final filePath in filePaths) {
          await lessonFilesNotifier.addFile(filePath);
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Files uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload files: $e')),
        );
      }
    }
  }

  void _takePhoto(BuildContext context, WidgetRef ref) async {
    try {
      final filePickerService = ref.read(filePickerServiceProvider);
      final filePaths = await filePickerService.pickMultipleFiles(FileSource.camera);
      
      if (filePaths.isNotEmpty) {
        final lessonFilesNotifier = ref.read(lessonFilesProvider(lessonId).notifier);
        
        for (final filePath in filePaths) {
          await lessonFilesNotifier.addFile(filePath);
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
}}