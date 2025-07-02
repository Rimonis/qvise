// lib/features/flashcards/creation/presentation/widgets/tag_selector_widget.dart

import 'package:flutter/material.dart';
import '../../../shared/domain/entities/flashcard_tag.dart';
import '/../../../core/theme/app_spacing.dart';

class TagSelectorWidget extends StatelessWidget {
  final FlashcardTag selectedTag;
  final void Function(FlashcardTag) onTagSelected;

  const TagSelectorWidget({
    super.key,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: FlashcardTag.systemTags.map((tag) {
            final isSelected = tag.id == selectedTag.id;
            final tagColor = Color(int.parse(tag.color.replaceAll('#', '0xFF')));
            
            return GestureDetector(
              onTap: () => onTagSelected(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? tagColor.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: isSelected ? tagColor : Colors.grey.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? tagColor : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          selectedTag.description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}