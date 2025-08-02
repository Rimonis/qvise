// lib/features/notes/presentation/widgets/note_card_widget.dart

import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/note.dart';

class NoteCardWidget extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteCardWidget({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        if (note.hasTitle) ...[
                          Text(
                            note.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        
                        // Content preview
                        Text(
                          note.hasTitle ? note.preview : note.displayTitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: note.hasTitle 
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : Theme.of(context).textTheme.titleMedium?.color,
                            fontWeight: note.hasTitle ? FontWeight.normal : FontWeight.w600,
                          ),
                          maxLines: note.hasTitle ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions menu
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Footer with metadata
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatLastModified(note.lastModified),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.sm),
                  
                  // Sync status indicator
                  if (note.syncStatus != 'synced') ...[
                    Icon(
                      note.syncStatus == 'pending' 
                          ? Icons.sync_outlined
                          : Icons.sync_problem_outlined,
                      size: 14,
                      color: note.syncStatus == 'pending'
                          ? Theme.of(context).hintColor
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      note.syncStatus == 'pending' ? 'Syncing...' : 'Sync failed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: note.syncStatus == 'pending'
                            ? Theme.of(context).hintColor
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastModified(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as date for older notes
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}