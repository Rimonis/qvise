import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson.freezed.dart';

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required String id,
    required String userId,
    required String subjectName,
    required String topicName,
    String? title,
    required DateTime createdAt, // When lesson was created
    DateTime? lockedAt, // When lesson was locked (null if unlocked)
    required DateTime nextReviewDate,
    DateTime? lastReviewedAt,
    required int reviewStage,
    required double proficiency,
    @Default(false) bool isLocked, // Whether lesson is locked
    @Default(false) bool isSynced,
    @Default(0) int flashcardCount, // Number of flashcards
    @Default(0) int fileCount, // Number of files
    @Default(0) int noteCount, // Number of notes
  }) = _Lesson;
  
  const Lesson._();
  
  // Display title or formatted date
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    // Format createdAt as "Jan 15, 2025"
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[createdAt.month - 1];
    final day = createdAt.day;
    final year = createdAt.year;
    return '$month $day, $year';
  }
  
  // Get the date when lesson was created for display
  String get dayCreated {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[createdAt.month - 1];
    final day = createdAt.day;
    return '$month $day';
  }
  
  // Check if review is due (only for locked lessons)
  bool get isReviewDue {
    if (!isLocked) return false;
    return DateTime.now().isAfter(nextReviewDate);
  }
  
  // Days until next review (only for locked lessons)
  int get daysUntilReview {
    if (!isLocked) return 0;
    final difference = nextReviewDate.difference(DateTime.now());
    return difference.inDays;
  }
  
  String get reviewStatus {
    if (!isLocked) return 'Unlocked';
    if (isReviewDue) return 'Due Now';
    if (daysUntilReview == 0) return 'Due Today';
    if (daysUntilReview == 1) return 'Due Tomorrow';
    return 'Due in $daysUntilReview days';
  }
  
  String get proficiencyColor {
    if (proficiency >= 0.8) return '#4CAF50'; // Green
    if (proficiency >= 0.6) return '#FFC107'; // Amber
    if (proficiency >= 0.4) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }
  
  // Review stage progress (0-5 stages)
  double get reviewStageProgress {
    return (reviewStage / 5.0).clamp(0.0, 1.0);
  }
  
  // Total content count
  int get totalContentCount => flashcardCount + fileCount + noteCount;
}