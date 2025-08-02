// lib/features/notes/presentation/screens/note_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final Note? existingNote;
  final String? initialContent;

  const NoteEditorScreen({
    super.key,
    required this.lessonId,
    this.existingNote,
    this.initialContent,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? widget.initialContent ?? ''
    );
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    // Listen for changes to enable save button
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existingNote != null ? 'Edit Note' : 'New Note'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleClose,
          ),
          actions: [
            TextButton(
              onPressed: _canSave() ? _saveNote : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Title input
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Note title (optional)',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.titleLarge,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            
            // Content input
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Start writing your note...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: widget.existingNote == null,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: context.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (widget.existingNote != null)
                  IconButton(
                    onPressed: _showDeleteDialog,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Expanded(
                  child: Text(
                    _hasUnsavedChanges 
                        ? 'Tap Save to keep your changes'
                        : 'Start typing to make changes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canSave() {
    return _contentController.text.trim().isNotEmpty && 
           !_isSaving && 
           _hasUnsavedChanges;
  }

  Future<void> _saveNote() async {
    if (!_canSave()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.existingNote != null) {
        // Update existing note
        final updateUseCase = ref.read(updateNoteProvider);
        final result = await updateUseCase(
          noteId: widget.existingNote!.id,
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          content: _contentController.text.trim(),
        );

        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update note: ${failure.userFriendlyMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          (_) {
            setState(() => _hasUnsavedChanges = false);
            if (mounted) {
              // Refresh the notes list
              ref.invalidate(lessonNotesProvider(widget.lessonId));
              Navigator.of(context).pop(true);
            }
          },
        );
      } else {
        // Create new note
        final createUseCase = ref.read(createNoteProvider);
        final result = await createUseCase(
          lessonId: widget.lessonId,
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          content: _contentController.text.trim(),
        );

        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save note: ${failure.userFriendlyMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          (_) {
            setState(() => _hasUnsavedChanges = false);
            if (mounted) {
              // Refresh the notes list
              ref.invalidate(lessonNotesProvider(widget.lessonId));
              Navigator.of(context).pop(true);
            }
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    return await _showUnsavedChangesDialog();
  }

  void _handleClose() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final shouldClose = await _showUnsavedChangesDialog();
    if (shouldClose && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showDeleteDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${widget.existingNote!.displayTitle}"?'),
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

    if (shouldDelete && mounted) {
      setState(() => _isSaving = true);
      
      try {
        final deleteUseCase = ref.read(deleteNoteProvider);
        final result = await deleteUseCase(widget.existingNote!.id);
        
        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete note: ${failure.userFriendlyMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          (_) {
            if (mounted) {
              // Refresh the notes list
              ref.invalidate(lessonNotesProvider(widget.lessonId));
              Navigator.of(context).pop(true);
            }
          },
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }
}