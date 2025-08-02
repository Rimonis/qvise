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
        color: context.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Quick add input
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Quick note...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expand button
                    IconButton(
                      onPressed: _openFullEditor,
                      icon: const Icon(Icons.open_in_full),
                      tooltip: 'Open full editor',
                    ),
                    // Add button
                    IconButton(
                      onPressed: _canSave() ? _saveQuickNote : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      tooltip: 'Add note',
                    ),
                  ],
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              textCapitalization: TextCapitalization.sentences,
              maxLines: _isExpanded ? 5 : 1,
              onTap: () => setState(() => _isExpanded = true),
              onSubmitted: (_) => _canSave() ? _saveQuickNote() : null,
            ),
          ),
          
          // Expanded actions
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: context.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _collapse,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: _openFullEditor,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Full Editor'),
                  ),
                  const Spacer(),
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
      await createUseCase(
        lessonId: widget.lessonId,
        content: _controller.text.trim(),
      );

      // Clear input and collapse
      _controller.clear();
      setState(() {
        _isExpanded = false;
        _isSaving = false;
      });
      _focusNode.unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add note: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _openFullEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          lessonId: widget.lessonId,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _collapse() {
    setState(() => _isExpanded = false);
    _focusNode.unfocus();
  }
}