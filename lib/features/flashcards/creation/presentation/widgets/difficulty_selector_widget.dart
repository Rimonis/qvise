// lib/features/flashcards/creation/presentation/widgets/difficulty_selector_widget.dart

import 'package:flutter/material.dart';
import '../../domain/entities/flashcard_difficulty.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class DifficultySelectororWidget extends StatelessWidget {
  final FlashcardDifficulty selectedDifficulty;
  final void Function(FlashcardDifficulty) onDifficultySelected;

  const DifficultySelectororWidget({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty Level',
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: FlashcardDifficulty.values.map((difficulty) {
            final isSelected = difficulty == selectedDifficulty;
            final color = _getDifficultyColor(context, difficulty);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: difficulty != FlashcardDifficulty.values.last
                      ? AppSpacing.sm
                      : 0,
                ),
                child: GestureDetector(
                  onTap: () => onDifficultySelected(difficulty),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : context.surfaceVariantColor,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                      border: Border.all(
                        color: isSelected ? color : context.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          difficulty.emoji,
                          style: context.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          difficulty.label,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? color : context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          difficulty.description,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? color.withOpacity(0.8)
                                : context.textTertiaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getDifficultyColor(
      BuildContext context, FlashcardDifficulty difficulty) {
    switch (difficulty) {
      case FlashcardDifficulty.easy:
        return context.successColor;
      case FlashcardDifficulty.medium:
        return context.warningColor;
      case FlashcardDifficulty.hard:
        return context.errorColor;
    }
  }
}