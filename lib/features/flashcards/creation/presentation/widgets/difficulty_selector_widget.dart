// lib/features/flashcards/creation/presentation/widgets/difficulty_selector_widget.dart

import 'package:flutter/material.dart';
import '../../domain/entities/flashcard_difficulty.dart';
import '/../../../core/theme/app_spacing.dart';

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
        const Text(
          'Difficulty Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: FlashcardDifficulty.values.map((difficulty) {
            final isSelected = difficulty == selectedDifficulty;
            
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: difficulty != FlashcardDifficulty.values.last ? AppSpacing.sm : 0,
                ),
                child: GestureDetector(
                  onTap: () => onDifficultySelected(difficulty),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? _getDifficultyColor(difficulty).withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      border: Border.all(
                        color: isSelected 
                          ? _getDifficultyColor(difficulty) 
                          : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          difficulty.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          difficulty.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                              ? _getDifficultyColor(difficulty) 
                              : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          difficulty.description,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected 
                              ? _getDifficultyColor(difficulty).withValues(alpha: 0.8)
                              : Colors.grey[600],
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

  Color _getDifficultyColor(FlashcardDifficulty difficulty) {
    switch (difficulty) {
      case FlashcardDifficulty.easy:
        return Colors.green;
      case FlashcardDifficulty.medium:
        return Colors.orange;
      case FlashcardDifficulty.hard:
        return Colors.red;
    }
  }
}