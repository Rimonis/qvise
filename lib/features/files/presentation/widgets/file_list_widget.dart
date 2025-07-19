// lib/features/files/presentation/widgets/file_list_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../providers/file_providers.dart';
import 'file_list_item.dart';

class FileListWidget extends ConsumerWidget {
  final String lessonId;

  const FileListWidget({super.key, required this.lessonId});

  void _showAddFileOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Add File',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.blue),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture a new photo'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final path = await ref
                      .read(filePickerServiceProvider)
                      .pickFile(FileSource.camera);
                  if (path != null) {
                    ref.read(lessonFilesProvider(lessonId).notifier).addFile(path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select from your photos'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final path = await ref
                      .read(filePickerServiceProvider)
                      .pickFile(FileSource.gallery);
                  if (path != null) {
                    ref.read(lessonFilesProvider(lessonId).notifier).addFile(path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_file, color: Colors.orange),
                ),
                title: const Text('Browse Files'),
                subtitle: const Text('PDF, documents, and more'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final path = await ref
                      .read(filePickerServiceProvider)
                      .pickFile(FileSource.files);
                  if (path != null) {
                    ref.read(lessonFilesProvider(lessonId).notifier).addFile(path);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsyncValue = ref.watch(lessonFilesProvider(lessonId));

    return Scaffold(
      body: filesAsyncValue.when(
        data: (files) {
          if (files.isEmpty) {
            return Center(
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
                    'No files yet',
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add photos, PDFs, and documents to this lesson',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFileOptions(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add File'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return FileListItem(
                file: files[index],
                onDeleted: () {
                  // Refresh the starred files if needed
                  ref.read(starredFilesProvider.notifier).refresh();
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error loading files',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                err.toString(),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(lessonFilesProvider(lessonId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: filesAsyncValue.maybeWhen(
        data: (files) => files.isNotEmpty 
            ? FloatingActionButton(
                onPressed: () => _showAddFileOptions(context, ref),
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}