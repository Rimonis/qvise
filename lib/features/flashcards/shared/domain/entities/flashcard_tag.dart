// lib/features/flashcards/shared/domain/entities/flashcard_tag.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'flashcard_tag.freezed.dart';

@freezed
class FlashcardTag with _$FlashcardTag {
  const factory FlashcardTag({
    required String id,
    required String name,
    required String emoji,
    required String color, // Hex color code
    required String description,
    @Default(false) bool isCustom, // User-created vs system tags
    FlashcardTagCategory? category,
    Map<String, dynamic>? settings, // Tag-specific settings (e.g., LaTeX support)
  }) = _FlashcardTag;
  
  const FlashcardTag._();
  
  // Predefined system tags
  static const definition = FlashcardTag(
    id: 'definition',
    name: 'Definition',
    emoji: '📝',
    color: '#3B82F6',
    description: 'Key terms and their meanings - perfect for vocabulary building',
    category: FlashcardTagCategory.core,
  );
  
  static const concept = FlashcardTag(
    id: 'concept',
    name: 'Concept',
    emoji: '🧠',
    color: '#8B5CF6',
    description: 'Understanding relationships and ideas between different topics',
    category: FlashcardTagCategory.core,
  );
  
  static const formula = FlashcardTag(
    id: 'formula',
    name: 'Formula',
    emoji: '📐',
    color: '#10B981',
    description: 'Mathematical and scientific equations with variables',
    category: FlashcardTagCategory.core,
    settings: {'supportsLatex': true, 'enableMathKeyboard': true},
  );
  
  static const process = FlashcardTag(
    id: 'process',
    name: 'Process',
    emoji: '📊',
    color: '#F59E0B',
    description: 'Step-by-step procedures and methodologies',
    category: FlashcardTagCategory.core,
  );
  
  static const example = FlashcardTag(
    id: 'example',
    name: 'Example',
    emoji: '🎯',
    color: '#EF4444',
    description: 'Specific instances, case studies, and practical applications',
    category: FlashcardTagCategory.core,
  );
  
  static const qa = FlashcardTag(
    id: 'qa',
    name: 'Q&A',
    emoji: '❓',
    color: '#6366F1',
    description: 'Direct question and answer pairs for quick recall',
    category: FlashcardTagCategory.core,
  );
  
  // Advanced tags (can be added later)
  static const connection = FlashcardTag(
    id: 'connection',
    name: 'Connection',
    emoji: '🔗',
    color: '#06B6D4',
    description: 'Linking different concepts and showing relationships',
    category: FlashcardTagCategory.advanced,
  );
  
  static const scenario = FlashcardTag(
    id: 'scenario',
    name: 'Scenario',
    emoji: '🎭',
    color: '#84CC16',
    description: 'Situational problem-solving and real-world applications',
    category: FlashcardTagCategory.advanced,
  );
  
  static const comparison = FlashcardTag(
    id: 'comparison',
    name: 'Comparison',
    emoji: '📈',
    color: '#F97316',
    description: 'Similarities, differences, and contrasting concepts',
    category: FlashcardTagCategory.advanced,
  );
  
  static const historical = FlashcardTag(
    id: 'historical',
    name: 'Historical',
    emoji: '🏛️',
    color: '#A855F7',
    description: 'Dates, events, chronology, and historical context',
    category: FlashcardTagCategory.advanced,
  );
  
  static const language = FlashcardTag(
    id: 'language',
    name: 'Language',
    emoji: '🗣️',
    color: '#EC4899',
    description: 'Vocabulary, translations, and language learning',
    category: FlashcardTagCategory.advanced,
  );
  
  static const visual = FlashcardTag(
    id: 'visual',
    name: 'Visual',
    emoji: '🎨',
    color: '#14B8A6',
    description: 'Diagrams, charts, images, and visual representations',
    category: FlashcardTagCategory.advanced,
  );
  
  // Get all system tags (core tags for initial release)
  static List<FlashcardTag> get systemTags => [
    definition, concept, formula, process, example, qa,
  ];
  
  // Get all tags including advanced (for future releases)
  static List<FlashcardTag> get allSystemTags => [
    definition, concept, formula, process, example, qa,
    connection, scenario, comparison, historical, language, visual,
  ];
}

enum FlashcardTagCategory {
  core,      // Essential learning types
  advanced,  // Complex learning types  
  subject,   // Subject-specific tags
  custom,    // User-created tags
}