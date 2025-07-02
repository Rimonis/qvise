// lib/features/flashcards/creation/presentation/widgets/hint_input_widget.dart

import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_spacing.dart';

class HintInputWidget extends StatefulWidget {
  final List<String> hints;
  final void Function(String) onHintAdded;
  final void Function(int) onHintRemoved;

  const HintInputWidget({
    super.key,
    required this.hints,
    required this.onHintAdded,
    required this.onHintRemoved,
  });

  @override
  State<HintInputWidget> createState() => _HintInputWidgetState();
}

class _HintInputWidgetState extends State<HintInputWidget> {
  final _hintController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _hintController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addHint() {
    final hint = _hintController.text.trim();
    if (hint.isNotEmpty) {
      widget.onHintAdded(hint);
      _hintController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Hints (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: Colors.amber[700],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Add helpful hints to guide learning',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Add hint input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hintController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Enter a helpful hint...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: (_) => _addHint(),
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: _addHint,
              icon: const Icon(Icons.add_circle),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        
        // Display existing hints
        if (widget.hints.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Hints (${widget.hints.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...widget.hints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final hint = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            hint,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => widget.onHintRemoved(index),
                          icon: const Icon(Icons.close),
                          iconSize: 18,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(24, 24),
                            padding: EdgeInsets.zero,
                          ),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}