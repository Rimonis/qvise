// lib/features/notes/presentation/widgets/note_quick_add_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../providers/note_providers.dart';
import '../screens/note_editor_screen.dart';

class NoteQuickAddWidget extends ConsumerStatefulWidget {
  final String lessonId;

  const NoteQuickAddWidget({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<NoteQuickAddWidget> createState() => _NoteQuickAddWidgetState();
}

class _NoteQuickAddWidgetState extends ConsumerState<NoteQuickAddWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: _isExpanded 
              ? context.colorScheme.primary 
              : context.colorScheme.outline.withValues(alpha: 0.5),
          width: _isExpanded ? 2 : 1,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isExpanded)
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = true;
                });
                _focusNode.requestFocus();
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Add a quick note...',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Type your note here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      filled: true,
                      fillColor: context.colorScheme.surfaceContainerHighest,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : _collapse,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: _canSave() ? _openFullEditor : null,
                        icon: const Icon(Icons.open_in_full, size: 16),
                        label: const Text('Full Editor'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: _canSave() ? _saveQuickNote : null,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add, size: 16),
                        label: const Text('Add Note'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _canSave() {
    return _controller.text.trim().isNotEmpty && !_isSaving;
  }

  Future<void> _saveQuickNote() async {
    if (!_canSave()) return;

    setState(() => _isSaving = true);

    try {
      final createUseCase = ref.read(createNoteProvider);
      final result = await createUseCase(
        lessonId: widget.lessonId,
        content: _controller.text.trim(),
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add note: ${failure.userFriendlyMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        (_) {
          // Clear input and collapse
          _controller.clear();
          setState(() {
            _isExpanded = false;
            _isSaving = false;
          });
          _focusNode.unfocus();

          // Refresh notes list
          ref.invalidate(lessonNotesProvider(widget.lessonId));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note added'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openFullEditor() {
    final noteContent = _controller.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          lessonId: widget.lessonId,
          initialContent: noteContent,
        ),
        fullscreenDialog: true,
      ),
    ).then((saved) {
      if (saved == true) {
        _controller.clear();
        _collapse();
      }
    });
  }

  void _collapse() {
    setState(() => _isExpanded = false);
    _focusNode.unfocus();
  }
}