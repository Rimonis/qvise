// test/features/content/data/repositories/content_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/data/models/lesson_model.dart';
import 'package:qvise/features/content/data/models/subject_model.dart';
import 'package:qvise/features/content/data/models/topic_model.dart';
import 'package:qvise/features/content/data/repositories/content_repository_impl.dart';
import 'package:qvise/features/content/domain/entities/subject.dart';
import 'package:qvise/features/content/domain/entities/topic.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/core/error/app_failure.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late ContentRepositoryImpl repository;
  late MockContentLocalDataSource mockLocalDataSource;
  late MockContentRemoteDataSource mockRemoteDataSource;
  late MockIUnitOfWork mockUnitOfWork;
  late MockInternetConnectionChecker mockConnectionChecker;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockLocalDataSource = MockContentLocalDataSource();
    mockRemoteDataSource = MockContentRemoteDataSource();
    mockUnitOfWork = MockIUnitOfWork();
    mockConnectionChecker = MockInternetConnectionChecker();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    repository = ContentRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      unitOfWork: mockUnitOfWork,
      connectionChecker: mockConnectionChecker,
      firebaseAuth: mockFirebaseAuth,
    );

    // Correctly mock the user and uid
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_user_id');
  });

  group('getSubjects', () {
    final tSubject = Subject(
      name: 'Test Subject',
      userId: 'test_user_id',
      proficiency: 0.5,
      lessonCount: 1,
      topicCount: 1,
      lastStudied: DateTime.now(),
      createdAt: DateTime.now(),
    );
    final tSubjectModel = SubjectModel.fromEntity(tSubject);

    test('should return list of subjects from local data source', () async {
      // arrange
      when(mockLocalDataSource.getSubjects(any))
          .thenAnswer((_) async => [tSubjectModel]);
      // act
      final result = await repository.getSubjects();
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (subjects) => expect(subjects, [tSubject]),
      );
      verify(mockLocalDataSource.getSubjects('test_user_id'));
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return AppFailure when user is not authenticated', () async {
      // arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      // act
      final result = await repository.getSubjects();
      // assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, 
            const AppFailure(type: FailureType.auth, message: 'User not authenticated')),
        (subjects) => fail('Should not return subjects'),
      );
    });
  });

  group('getTopicsBySubject', () {
    final tTopic = Topic(
      name: 'Test Topic',
      subjectName: 'Test Subject',
      userId: 'test_user_id',
      proficiency: 0.5,
      lessonCount: 1,
      lastStudied: DateTime.now(),
      createdAt: DateTime.now(),
    );
    final tTopicModel = TopicModel.fromEntity(tTopic);

    test('should return list of topics from local data source', () async {
      // arrange
      when(mockLocalDataSource.getTopicsBySubject(any, any))
          .thenAnswer((_) async => [tTopicModel]);
      // act
      final result = await repository.getTopicsBySubject('Test Subject');
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (topics) => expect(topics, [tTopic]),
      );
      verify(mockLocalDataSource.getTopicsBySubject('test_user_id', 'Test Subject'));
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('getLessonsByTopic', () {
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
    final tLessonModel = LessonModel.fromEntity(tLesson);

    test('should return list of lessons from local data source', () async {
      // arrange
      when(mockLocalDataSource.getLessonsByTopic(any, any, any))
          .thenAnswer((_) async => [tLessonModel]);
      // act
      final result = await repository.getLessonsByTopic('Test Subject', 'Test Topic');
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (lessons) => expect(lessons, [tLesson]),
      );
      verify(mockLocalDataSource.getLessonsByTopic('test_user_id', 'Test Subject', 'Test Topic'));
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('deleteLesson', () {
    const tLessonId = '1';

    test('should delete lesson successfully when online', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);
      when(mockRemoteDataSource.deleteLesson(any))
          .thenAnswer((_) async => Future.value());
      when(mockLocalDataSource.deleteLesson(any))
          .thenAnswer((_) async => Future.value());
      
      // act
      final result = await repository.deleteLesson(tLessonId);
      
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (_) {
          verify(mockRemoteDataSource.deleteLesson(tLessonId));
          verify(mockLocalDataSource.deleteLesson(tLessonId));
        },
      );
    });

    test('should delete lesson locally when offline', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => false);
      when(mockLocalDataSource.deleteLesson(any))
          .thenAnswer((_) async => Future.value());
      
      // act
      final result = await repository.deleteLesson(tLessonId);
      
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (_) {
          verify(mockLocalDataSource.deleteLesson(tLessonId));
          verifyNever(mockRemoteDataSource.deleteLesson(any));
        },
      );
    });
  });
}