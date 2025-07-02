// lib/features/flashcards/creation/presentation/widgets/flashcard_preview_widget.dart

import 'package:flutter/material.dart';
import '../../../shared/domain/entities/flashcard_tag.dart';
import '../../domain/entities/flashcard_difficulty.dart';
import '/../../../core/theme/app_spacing.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    final tagColor = Color(int.parse(widget.tag.color.replaceAll('#', '0xFF')));
    
    return Padding(
      padding: AppSpacing.screenPaddingAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Preview label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Preview Mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Flashcard
          GestureDetector(
            onTap: _flipCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final isShowingFront = _flipAnimation.value < 0.5;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipAnimation.value * 3.14159),
                  child: isShowingFront ? _buildFrontCard(tagColor) : _buildBackCard(tagColor),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Tap instruction
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Tap card to flip',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          
          // Card info
          const SizedBox(height: AppSpacing.lg),
          _buildCardInfo(tagColor),
        ],
      ),
    );
  }

  Widget _buildFrontCard(Color tagColor) {
    return Container(
      width: double.infinity,
      height: 300,
      padding: AppSpacing.paddingAllLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: tagColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.tag.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      widget.tag.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tagColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                widget.difficulty.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Content
          Expanded(
            child: Center(
              child: Text(
                widget.frontContent,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Front indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              'FRONT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Color tagColor) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        width: double.infinity,
        height: 300,
        padding: AppSpacing.paddingAllLg,
        decoration: BoxDecoration(
          color: tagColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: tagColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.tag.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.tag.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tagColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  widget.difficulty.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      widget.backContent,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (widget.hints.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: AppSpacing.paddingAllSm,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 14,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Hints',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ...widget.hints.take(2).map((hint) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '• $hint',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber[800],
                                ),
                              ),
                            )),
                            if (widget.hints.length > 2)
                              Text(
                                '... and ${widget.hints.length - 2} more',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Back indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                'BACK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tagColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo(Color tagColor) {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Tag info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          widget.tag.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          widget.tag.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tagColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Difficulty info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Difficulty',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.difficulty.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          widget.difficulty.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (widget.notes != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}