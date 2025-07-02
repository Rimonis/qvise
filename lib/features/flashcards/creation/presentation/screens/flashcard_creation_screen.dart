// lib/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/flashcards/creation/domain/entities/flashcard_difficulty.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';
import '../widgets/tag_selector_widget.dart';
import '../widgets/difficulty_selector_widget.dart';
import '../widgets/flashcard_preview_widget.dart';
import '../widgets/hint_input_widget.dart';
import '../providers/flashcard_creation_providers.dart';

class FlashcardCreationScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String subjectName;
  final String topicName;

  const FlashcardCreationScreen({
    super.key,
    required this.lessonId,
    required this.subjectName,
    required this.topicName,
  });

  @override
  ConsumerState<FlashcardCreationScreen> createState() => _FlashcardCreationScreenState();
}

class _FlashcardCreationScreenState extends ConsumerState<FlashcardCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _notesController = TextEditingController();
  
  FlashcardTag _selectedTag = FlashcardTag.definition;
  FlashcardDifficulty _selectedDifficulty = FlashcardDifficulty.medium;
  List<String> _hints = [];
  bool _showPreview = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to trigger UI updates
    _frontController.addListener(_onTextChanged);
    _backController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Force UI update when text content changes
    if (mounted) {
      setState(() {
        // This will trigger rebuild and update button states
      });
    }
  }

  @override
  void dispose() {
    _frontController.removeListener(_onTextChanged);
    _backController.removeListener(_onTextChanged);
    _frontController.dispose();
    _backController.dispose();
    _notesController.dispose();
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

  Future<void> _createFlashcard() async {
  // In preview mode, we don't have access to the form, so validate manually
  if (_frontController.text.trim().isEmpty || _backController.text.trim().isEmpty) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill in both front and back content'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
    return;
  }

    // If not in preview mode, validate the form
    if (!_showPreview && !_formKey.currentState!.validate()) return;

  setState(() {
    _isCreating = true;
  });

  try {
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

    result.fold(
      (failure) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create flashcard: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        }
      },
      (flashcard) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flashcard created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true); // Return true to indicate success
            }
          });
        }
      },
    );
  } finally {
    if (mounted) {
      setState(() {
        _isCreating = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Flashcard'),
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
            // Context info
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

            // Tag Selection
            TagSelectorWidget(
              selectedTag: _selectedTag,
              onTagSelected: (tag) => setState(() => _selectedTag = tag),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Front Content
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

            // Back Content
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

            // Difficulty Selection
            DifficultySelectororWidget(
              selectedDifficulty: _selectedDifficulty,
              onDifficultySelected: (difficulty) => setState(() => _selectedDifficulty = difficulty),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Hints (Optional)
            HintInputWidget(
              hints: _hints,
              onHintAdded: _addHint,
              onHintRemoved: _removeHint,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Notes (Optional)
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

    return Center(
      child: FlashcardPreviewWidget(
        frontContent: _frontController.text,
        backContent: _backController.text,
        tag: _selectedTag,
        difficulty: _selectedDifficulty,
        hints: _hints,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Preview button
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
            
            // Create button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _canCreateFlashcard() ? _createFlashcard : null,
                icon: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
                label: Text(_isCreating ? 'Creating...' : 'Create Flashcard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateFlashcard() {
    return _frontController.text.trim().isNotEmpty && 
           _backController.text.trim().isNotEmpty &&
           !_isCreating;
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