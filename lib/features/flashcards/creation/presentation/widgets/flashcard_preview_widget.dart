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
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const FlashcardPreviewWidget({
    super.key,
    required this.frontContent,
    required this.backContent,
    required this.tag,
    required this.difficulty,
    required this.hints,
    this.notes,
    this.isFavorite = false,
    this.onToggleFavorite,
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
  bool _isNotesExpanded = false;

  // Track if we're currently dragging to prevent conflicts
  bool _isDragging = false;
  double _flipDirection = 1.0; // 1.0 for right, -1.0 for left

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

  void _flipCard({bool swipeRight = true}) {
    if (mounted && !_isDragging) {
      HapticFeedback.lightImpact();
      setState(() {
        _flipDirection = swipeRight ? 1.0 : -1.0;
      });
      if (_isShowingBack) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
      setState(() {
        _isShowingBack = !_isShowingBack;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _flipCard,
      onHorizontalDragStart: (_) {
        _isDragging = true;
      },
      onHorizontalDragEnd: (details) {
        _isDragging = false;
        // Only flip if horizontal velocity is significant
        if (details.primaryVelocity!.abs() > 100) {
          _flipCard(swipeRight: details.primaryVelocity! > 0);
        }
      },
      onHorizontalDragCancel: () {
        _isDragging = false;
      },
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          children: [
            // Spacer to center the card vertically
            const Spacer(flex: 1),

            // Card container with fixed height
            SizedBox(
              height: 350,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final isShowingFront = _flipAnimation.value < 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipAnimation.value * 3.14159 * _flipDirection),
                    child: isShowingFront ? _buildFrontCard() : _buildBackCard(),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            _buildFlipInstructions(),
            const SizedBox(height: AppSpacing.lg),

            // Info and notes section with flexible height
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    _buildCardInfo(),
                    if (_isShowingBack && widget.notes != null && widget.notes!.isNotEmpty)
                      _buildNotesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipInstructions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swipe, size: 16, color: context.textTertiaryColor),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Swipe or Tap to Flip',
            style: context.textTheme.bodySmall?.copyWith(color: context.textTertiaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFrontCard() {
    final tagColor = Color(int.parse(widget.tag.color.replaceAll('#', '0xFF')));
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
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
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        color: context.surfaceColor,
        child: Container(
          width: double.infinity,
          height: double.infinity,
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
        // Wrap in GestureDetector to prevent tap propagation
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // Consume tap
          child: Container(
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
        ),
        const Spacer(),
        if (widget.onToggleFavorite != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Consume tap to prevent card flip
            child: IconButton(
              icon: Icon(
                widget.isFavorite ? Icons.star : Icons.star_border,
                color: widget.isFavorite ? Colors.amber : context.iconColor,
              ),
              onPressed: widget.onToggleFavorite,
              tooltip: 'Toggle favorite',
            ),
          ),
        Text(widget.difficulty.emoji, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildHintsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        const Text('Hints:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ...widget.hints.asMap().entries.map((entry) {
          final index = entry.key;
          final hint = entry.value;
          final isRevealed = _revealedHints.contains(index);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
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
              child: Text(
                isRevealed ? hint : 'Tap to reveal hint',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCardInfo() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Consume tap
      child: Container(
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
      ),
    );
  }

  Widget _buildNotesSection() {
    final hasLongNotes = widget.notes!.length > 150;
    final displayNotes = _isNotesExpanded || !hasLongNotes
        ? widget.notes!
        : '${widget.notes!.substring(0, 150)}...';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasLongNotes
          ? () {
              setState(() {
                _isNotesExpanded = !_isNotesExpanded;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(top: AppSpacing.lg),
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: context.surfaceVariantColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notes', style: context.textTheme.titleSmall),
                if (hasLongNotes)
                  Icon(
                    _isNotesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: context.textSecondaryColor,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              displayNotes,
              style: context.textTheme.bodyMedium,
            ),
            if (hasLongNotes && !_isNotesExpanded)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Tap to read more',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textTertiaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ]
        ),
      ),
    );
  }
}