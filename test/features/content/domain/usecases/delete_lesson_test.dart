// test/features/content/domain/usecases/delete_lesson_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/usecases/delete_lesson.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late DeleteLesson usecase;
  late MockContentRepository mockContentRepository;

  setUp(() {
    mockContentRepository = MockContentRepository();
    usecase = DeleteLesson(mockContentRepository);
  });

  test('should delete a lesson from the repository', () async {
    // arrange
    when(mockContentRepository.deleteLesson(any))
        .thenAnswer((_) async => const Right(null));
    // act
    final result = await usecase('1');
    // assert
    expect(result, const Right(null));
    verify(mockContentRepository.deleteLesson('1'));
    verifyNoMoreInteractions(mockContentRepository);
  });
}
