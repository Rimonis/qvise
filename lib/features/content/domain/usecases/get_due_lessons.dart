// lib/features/content/domain/usecases/get_due_lessons.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/lesson.dart';
import '../repositories/content_repository.dart';

class GetDueLessons implements UseCase<List<Lesson>, NoParams> {
  final ContentRepository repository;

  GetDueLessons(this.repository);

  @override
  Future<Either<AppError, List<Lesson>>> call(NoParams params) async {
    return await repository.getDueLessons();
  }
}

/// Parameters for getting due lessons with filters
class GetDueLessonsParams {
  final String? subjectName;
  final String? topicName;
  final int? limit;
  final bool includeLocked;
  final DateTime? asOfDate;

  const GetDueLessonsParams({
    this.subjectName,
    this.topicName,
    this.limit,
    this.includeLocked = false,
    this.asOfDate,
  });
}

/// Extended use case with filtering capabilities
class GetDueLessonsWithFilter implements UseCase<List<Lesson>, GetDueLessonsParams> {
  final ContentRepository repository;

  GetDueLessonsWithFilter(this.repository);

  @override
  Future<Either<AppError, List<Lesson>>> call(GetDueLessonsParams params) async {
    final result = await repository.getDueLessons();
    
    return result.map((lessons) {
      var filteredLessons = lessons.where((lesson) {
        // Filter by subject if specified
        if (params.subjectName != null && lesson.subjectName != params.subjectName) {
          return false;
        }
        
        // Filter by topic if specified
        if (params.topicName != null && lesson.topicName != params.topicName) {
          return false;
        }
        
        // Filter locked lessons if not included
        if (!params.includeLocked && lesson.isLocked) {
          return false;
        }
        
        // Filter by date if specified
        if (params.asOfDate != null) {
          return lesson.nextReviewDate.isBefore(params.asOfDate!) || 
                 lesson.nextReviewDate.isAtSameMomentAs(params.asOfDate!);
        }
        
        return true;
      }).toList();
      
      // Sort by priority (overdue lessons first, then by next review date)
      filteredLessons.sort((a, b) {
        final now = params.asOfDate ?? DateTime.now();
        final aOverdue = a.nextReviewDate.isBefore(now);
        final bOverdue = b.nextReviewDate.isBefore(now);
        
        // If one is overdue and the other isn't, prioritize the overdue one
        if (aOverdue && !bOverdue) return -1;
        if (!aOverdue && bOverdue) return 1;
        
        // If both are overdue or both are not, sort by next review date
        return a.nextReviewDate.compareTo(b.nextReviewDate);
      });
      
      // Apply limit if specified
      if (params.limit != null && filteredLessons.length > params.limit!) {
        filteredLessons = filteredLessons.take(params.limit!).toList();
      }
      
      return filteredLessons;
    });
  }
}
