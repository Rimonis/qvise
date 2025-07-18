// test/features/content/domain/usecases/create_lesson_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/usecases/create_lesson.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/domain/entities/create_lesson_params.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late CreateLesson usecase;
  late MockContentRepository mockContentRepository;

  setUp(() {
    mockContentRepository = MockContentRepository();
    usecase = CreateLesson(mockContentRepository);
  });

  final tLesson = Lesson(
    id: '1',
    userId: 'test_user_id',
    subjectName: 'Test Subject',
    topicName: 'Test Topic',
    createdAt: DateTime.now(),
    nextReviewDate: DateTime.now(),
    reviewStage: 1,
    proficiency: 0.5,
  );
  final tParams = CreateLessonParams(
    subjectName: 'Test Subject',
    topicName: 'Test Topic',
    isNewSubject: true,
    isNewTopic: true,
  );

  test('should create a lesson from the repository', () async {
    // arrange
    when(mockContentRepository.createLesson(any))
        .thenAnswer((_) async => Right(tLesson));
    // act
    final result = await usecase(tParams);
    // assert
    expect(result, Right(tLesson));
    verify(mockContentRepository.createLesson(tParams));
    verifyNoMoreInteractions(mockContentRepository);
  });
}
