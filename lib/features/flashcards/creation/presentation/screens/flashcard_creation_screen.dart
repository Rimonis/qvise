// lib/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/flashcards/creation/domain/entities/flashcard_difficulty.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import '../widgets/tag_selector_widget.dart';
import '../widgets/difficulty_selector_widget.dart';
import '../widgets/flashcard_preview_widget.dart';
import '../widgets/hint_input_widget.dart';
import '../providers/flashcard_creation_providers.dart';

class FlashcardCreationScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String subjectName;
  final String topicName;
  final Flashcard? flashcardToEdit;

  const FlashcardCreationScreen({
    super.key,
    required this.lessonId,
    required this.subjectName,
    required this.topicName,
    this.flashcardToEdit,
  });

  @override
  ConsumerState<FlashcardCreationScreen> createState() =>
      _FlashcardCreationScreenState();
}

class _FlashcardCreationScreenState
    extends ConsumerState<FlashcardCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _notesController = TextEditingController();
  final _hintController = TextEditingController();

  late FlashcardTag _selectedTag;
  late FlashcardDifficulty _selectedDifficulty;
  late List<String> _hints;
  bool _showPreview = false;
  bool _isSaving = false;
  bool get _isEditing => widget.flashcardToEdit != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      final card = widget.flashcardToEdit!;
      _frontController.text = card.frontContent;
      _backController.text = card.backContent;
      _notesController.text = card.notes ?? '';
      _selectedTag = card.tag;
      _selectedDifficulty = FlashcardDifficulty.fromValue(card.difficulty);
      _hints = List<String>.from(card.hints ?? []);
    } else {
      _selectedTag = FlashcardTag.definition;
      _selectedDifficulty = FlashcardDifficulty.medium;
      _hints = [];
    }
    
    _frontController.addListener(_onTextChanged);
    _backController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _frontController.removeListener(_onTextChanged);
    _backController.removeListener(_onTextChanged);
    _frontController.dispose();
    _backController.dispose();
    _notesController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _addHint(String hint) {
    if (hint.trim().isNotEmpty && !_hints.contains(hint.trim())) {
      setState(() {
        _hints.add(hint.trim());
      });
    }
  }

  void _removeHint(int index) {
    setState(() {
      _hints.removeAt(index);
    });
  }

  Future<void> _saveFlashcard() async {
    final lastHint = _hintController.text.trim();
    if (lastHint.isNotEmpty) {
      _addHint(lastHint);
      _hintController.clear();
    }

    if (!_showPreview) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        final updatedFlashcard = widget.flashcardToEdit!.copyWith(
          frontContent: _frontController.text,
          backContent: _backController.text,
          tag: _selectedTag,
          difficulty: _selectedDifficulty.value,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          hints: _hints.isEmpty ? null : _hints,
        );

        final updateFlashcard = ref.read(updateFlashcardProvider);
        final result = await updateFlashcard(updatedFlashcard);
        
        if (mounted) {
          result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.userFriendlyMessage)));
            },
            (flashcard) {
              Navigator.of(context).pop(true);
            },
          );
        }
      } else {
        final createFlashcard = ref.read(createFlashcardProvider);
        final result = await createFlashcard(
          lessonId: widget.lessonId,
          frontContent: _frontController.text,
          backContent: _backController.text,
          tagId: _selectedTag.id,
          difficulty: _selectedDifficulty,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          hints: _hints.isEmpty ? null : _hints,
        );

        if (mounted) {
          result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.userFriendlyMessage)));
            },
            (flashcard) {
              Navigator.of(context).pop(true);
            },
          );
        }
      }
    } on AppFailure catch(failure) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.userFriendlyMessage)));
        }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Flashcard' : 'Create Flashcard'),
        centerTitle: true,
        actions: [
          if (_showPreview)
            TextButton(
              onPressed: () => setState(() => _showPreview = false),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingAll,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.book, color: context.primaryColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.topicName,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TagSelectorWidget(
              selectedTag: _selectedTag,
              onTagSelected: (tag) => setState(() => _selectedTag = tag),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _getFieldLabel('front'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _frontController,
              decoration: InputDecoration(
                hintText: _getFieldHint('front'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the front content';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _getFieldLabel('back'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _backController,
              decoration: InputDecoration(
                hintText: _getFieldHint('back'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the back content';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            DifficultySelectororWidget(
              selectedDifficulty: _selectedDifficulty,
              onDifficultySelected: (difficulty) =>
                  setState(() => _selectedDifficulty = difficulty),
            ),
            if (_selectedDifficulty == FlashcardDifficulty.hard)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'This is a hard card. Consider adding hints to help you learn.',
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: context.warningColor),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            HintInputWidget(
              controller: _hintController,
              hints: _hints,
              onHintAdded: _addHint,
              onHintRemoved: _removeHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add any additional notes or context...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_frontController.text.isEmpty || _backController.text.isEmpty) {
      return const Center(
        child: Text('Please fill in front and back content to preview'),
      );
    }

    final previewHints = List<String>.from(_hints);
    final pendingHint = _hintController.text.trim();
    if (pendingHint.isNotEmpty) {
      previewHints.add(pendingHint);
    }

    return Center(
      child: FlashcardPreviewWidget(
        frontContent: _frontController.text,
        backContent: _backController.text,
        tag: _selectedTag,
        difficulty: _selectedDifficulty,
        hints: previewHints,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isFavorite: _isEditing ? widget.flashcardToEdit!.isFavorite : false,
        onToggleFavorite: null,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _canPreview()
                    ? () => setState(() => _showPreview = !_showPreview)
                    : null,
                icon: Icon(_showPreview ? Icons.edit : Icons.visibility),
                label: Text(_showPreview ? 'Edit' : 'Preview'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _canSaveFlashcard() ? _saveFlashcard : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isSaving ? 'Saving...' : (_isEditing ? 'Update Flashcard' : 'Create Flashcard')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSaveFlashcard() {
    return _frontController.text.trim().isNotEmpty &&
        _backController.text.trim().isNotEmpty &&
        !_isSaving;
  }

  bool _canPreview() {
    return _frontController.text.trim().isNotEmpty &&
        _backController.text.trim().isNotEmpty;
  }

  String _getFieldLabel(String field) {
    switch (_selectedTag.id) {
      case 'definition':
        return field == 'front' ? 'Term' : 'Definition';
      case 'qa':
        return field == 'front' ? 'Question' : 'Answer';
      case 'formula':
        return field == 'front' ? 'Formula Name' : 'Formula & Explanation';
      case 'concept':
        return field == 'front' ? 'Concept' : 'Explanation';
      case 'process':
        return field == 'front' ? 'Process Name' : 'Steps';
      case 'example':
        return field == 'front' ? 'Example Prompt' : 'Example Details';
      default:
        return field == 'front' ? 'Front' : 'Back';
    }
  }

  String _getFieldHint(String field) {
    switch (_selectedTag.id) {
      case 'definition':
        return field == 'front'
            ? 'Enter the term to define...'
            : 'Provide a clear definition...';
      case 'qa':
        return field == 'front'
            ? 'What is your question?'
            : 'What is the answer?';
      case 'formula':
        return field == 'front'
            ? 'Enter formula name or context...'
            : 'Write the formula and explain variables...';
      case 'concept':
        return field == 'front'
            ? 'Enter the concept name...'
            : 'Explain the concept clearly...';
      case 'process':
        return field == 'front'
            ? 'Enter the process name...'
            : 'List the steps in order...';
      case 'example':
        return field == 'front'
            ? 'Describe what to demonstrate...'
            : 'Provide a specific example...';
      default:
        return field == 'front'
            ? 'What goes on the front?'
            : 'What goes on the back?';
    }
  }
}
