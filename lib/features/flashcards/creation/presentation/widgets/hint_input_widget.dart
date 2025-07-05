// lib/features/flashcards/creation/presentation/widgets/hint_input_widget.dart

import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class HintInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final List<String> hints;
  final void Function(String) onHintAdded;
  final void Function(int) onHintRemoved;

  const HintInputWidget({
    super.key,
    required this.controller,
    required this.hints,
    required this.onHintAdded,
    required this.onHintRemoved,
  });

  @override
  State<HintInputWidget> createState() => _HintInputWidgetState();
}

class _HintInputWidgetState extends State<HintInputWidget> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _addHint(keepFocus: false);
    }
  }

  void _addHint({bool keepFocus = true}) {
    final hint = widget.controller.text.trim();
    if (hint.isNotEmpty) {
      widget.onHintAdded(hint);
      widget.controller.clear();
    }
    if (keepFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hints (Optional)',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: context.warningColor,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Add helpful hints to guide learning',
          style: context.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
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
              onPressed: () => _addHint(),
              icon: const Icon(Icons.add_circle),
              style: IconButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.onPrimaryColor,
              ),
            ),
          ],
        ),
        if (widget.hints.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: context.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: context.warningColor.withOpacity(0.3),
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
                      color: context.warningColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Hints (${widget.hints.length})',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.warningColor,
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
                            color: context.warningColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.onPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            hint,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.warningColor,
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
                          color: context.textSecondaryColor,
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