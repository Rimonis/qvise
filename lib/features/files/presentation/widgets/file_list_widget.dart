// lib/features/files/presentation/widgets/file_list_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/files/presentation/providers/file_providers.dart';
import 'package:qvise/features/files/presentation/widgets/file_list_item.dart';
import 'package:qvise/features/content/presentation/providers/content_state_providers.dart';
import 'package:qvise/core/services/file_picker_service.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class FileListWidget extends ConsumerWidget {
  final String lessonId;

  const FileListWidget({
    super.key,
    required this.lessonId,
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
            // Add file button
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: FileListItem(
                        file: file,
                        onDeleted: () {
                          // Refresh files and update counts
                          _refreshAfterFileChange(ref);
                        },
                      ),
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
            Text(
              'Error loading files',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
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
              'Add files to enhance your lesson content',
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Add File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture with camera'),
              onTap: () async {
                Navigator.pop(context);
                await _addFile(context, ref, FileSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _addFile(context, ref, FileSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Browse Files'),
              subtitle: const Text('Documents, PDFs, etc.'),
              onTap: () async {
                Navigator.pop(context);
                await _addFile(context, ref, FileSource.files);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _addFile(BuildContext context, WidgetRef ref, FileSource source) async {
    try {
      final filePicker = ref.read(filePickerServiceProvider);
      final filePath = await filePicker.pickFile(source);
      
      if (filePath != null) {
        await ref.read(lessonFilesProvider(lessonId).notifier).addFile(filePath);
        
        // Refresh files and update all related data
        _refreshAfterFileChange(ref);
        
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File added successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add file: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    }
  }

  void _refreshAfterFileChange(WidgetRef ref) {
    // Refresh file list
    ref.invalidate(lessonFilesProvider(lessonId));
    
    // Refresh lesson data to update file count
    ref.invalidate(lessonProvider(lessonId));
    
    // Refresh unlocked lessons list
    ref.invalidate(unlockedLessonsProvider);
    
    // Refresh subject/topic lists that show file counts
    ref.invalidate(subjectsNotifierProvider);
  }
}