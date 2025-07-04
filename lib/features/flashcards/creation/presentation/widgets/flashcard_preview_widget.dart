// lib/features/flashcards/creation/presentation/widgets/flashcard_preview_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';
import 'package:qvise/features/flashcards/creation/domain/entities/flashcard_difficulty.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class FlashcardPreviewWidget extends StatefulWidget {
  final String frontContent;
  final String backContent;
  final FlashcardTag tag;
  final FlashcardDifficulty difficulty;
  final List<String> hints;
  final String? notes;

  const FlashcardPreviewWidget({
    super.key,
    required this.frontContent,
    required this.backContent,
    required this.tag,
    required this.difficulty,
    required this.hints,
    this.notes,
  });

  @override
  State<FlashcardPreviewWidget> createState() => _FlashcardPreviewWidgetState();
}

class _FlashcardPreviewWidgetState extends State<FlashcardPreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  bool _isShowingBack = false;
  final Set<int> _revealedHints = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isShowingBack) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isShowingBack = !_isShowingBack;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPaddingAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity!.abs() > 300) {
                HapticFeedback.lightImpact();
                _flipCard();
              }
            },
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final isShowingFront = _flipAnimation.value < 0.5;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipAnimation.value * 3.14159),
                  child: isShowingFront ? _buildFrontCard() : _buildBackCard(),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCardInfo(),
          if (_isShowingBack && widget.notes != null && widget.notes!.isNotEmpty)
            _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildFrontCard() {
    final tagColor = Color(int.parse(widget.tag.color.replaceAll('#', '0xFF')));
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        height: 300,
        padding: AppSpacing.paddingAllLg,
        child: Column(
          children: [
            _buildCardHeader(tagColor),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    widget.frontContent,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (widget.hints.isNotEmpty) _buildHintsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    final tagColor = Color(int.parse(widget.tag.color.replaceAll('#', '0xFF')));
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Card(
        elevation: 4,
        color: context.surfaceColor,
        child: Container(
          width: double.infinity,
          height: 300,
          padding: AppSpacing.paddingAllLg,
          child: Column(
            children: [
              _buildCardHeader(tagColor),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.backContent,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Color tagColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: tagColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Row(
            children: [
              Text(widget.tag.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                widget.tag.name,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: tagColor),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(widget.difficulty.emoji, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildHintsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        const Text('Hints:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...widget.hints.asMap().entries.map((entry) {
          final index = entry.key;
          final hint = entry.value;
          final isRevealed = _revealedHints.contains(index);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isRevealed) {
                  _revealedHints.remove(index);
                } else {
                  _revealedHints.add(index);
                }
              });
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: AppSpacing.paddingAllSm,
              decoration: BoxDecoration(
                color: isRevealed
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(isRevealed ? hint : 'Tap to reveal hint'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCardInfo() {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type', style: context.textTheme.bodySmall),
              Text(widget.tag.name, style: context.textTheme.titleSmall),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Difficulty', style: context.textTheme.bodySmall),
              Text(widget.difficulty.label, style: context.textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: context.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(widget.notes!),
        ],
      ),
    );
  }
}