// lib/features/notes/presentation/widgets/note_list_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';
import '../screens/note_editor_screen.dart';
import 'note_card_widget.dart';
import 'note_quick_add_widget.dart';

class NoteListWidget extends ConsumerWidget {
  final String lessonId;

  const NoteListWidget({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(lessonNotesProvider(lessonId));

    return notesAsync.when(
      data: (notes) => _buildNotesList(context, ref, notes),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildNotesList(BuildContext context, WidgetRef ref, List<Note> notes) {
    return Column(
      children: [
        // Quick add note widget
        NoteQuickAddWidget(lessonId: lessonId),
        
        const SizedBox(height: AppSpacing.md),
        
        // Notes list
        Expanded(
          child: notes.isEmpty
              ? _buildEmptyState(context)
              : _buildNotesListView(context, ref, notes),
        ),
      ],
    );
  }

  Widget _buildNotesListView(BuildContext context, WidgetRef ref, List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: NoteCardWidget(
            note: note,
            onTap: () => _openNoteEditor(context, note),
            onDelete: () => _deleteNote(context, ref, note),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Theme.of(context).hintColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start taking notes to remember key points\nfrom your lesson',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _openNoteEditor(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Note'),
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
            'Failed to load notes',
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
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _refreshNotes(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _openNoteEditor(BuildContext context, Note? note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          lessonId: lessonId,
          existingNote: note,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context, WidgetRef ref, Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.displayTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final deleteUseCase = ref.read(deleteNoteProvider);
        await deleteUseCase(note.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete note: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _refreshNotes(BuildContext context) {
    // Trigger a refresh by invalidating the provider
    // This will be handled by Riverpod's refresh mechanism
  }
}