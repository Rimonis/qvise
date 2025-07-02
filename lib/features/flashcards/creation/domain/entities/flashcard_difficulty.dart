enum FlashcardDifficulty {
  easy(value: 0.25, label: 'Easy', emoji: '🟢', description: 'Simple recall'),
  medium(value: 0.5, label: 'Medium', emoji: '🟡', description: 'Moderate challenge'),
  hard(value: 0.75, label: 'Hard', emoji: '🔴', description: 'Complex concept');

  const FlashcardDifficulty({
    required this.value,
    required this.label,
    required this.emoji,
    required this.description,
  });

  final double value;
  final String label;
  final String emoji;
  final String description;

  static FlashcardDifficulty fromValue(double value) {
    if (value <= 0.33) return easy;
    if (value <= 0.66) return medium;
    return hard;
  }
}