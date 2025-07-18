// test/core/data/unit_of_work_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:qvise/core/data/database/app_database.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../mocks.mocks.dart';

void main() {
  // Initialize FFI for sqflite for the test environment
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late SqliteUnitOfWork unitOfWork;
  late MockContentLocalDataSource mockContentLocalDataSource;
  late MockFlashcardLocalDataSource mockFlashcardLocalDataSource;
  late MockDatabase mockDatabase;
  late MockTransaction mockTransaction;

  setUp(() {
    mockContentLocalDataSource = MockContentLocalDataSource();
    mockFlashcardLocalDataSource = MockFlashcardLocalDataSource();
    mockDatabase = MockDatabase();
    mockTransaction = MockTransaction();
    unitOfWork = SqliteUnitOfWork(
      content: mockContentLocalDataSource,
      flashcard: mockFlashcardLocalDataSource,
    );
    // Inject the mock database before each test
    AppDatabase.setDatabase(mockDatabase);
  });

  test('transaction should correctly handle a successful transaction', () async {
    // arrange
    // When the transaction is started, execute the passed function
    when(mockDatabase.transaction<String>(any, exclusive: anyNamed('exclusive')))
        .thenAnswer((invocation) async {
      final action = invocation.positionalArguments[0] as Future<String> Function(Transaction);
      return await action(mockTransaction);
    });

    // Stub the methods that will be called INSIDE the transaction
    when(mockContentLocalDataSource.getSubjects('test_user')).thenAnswer((_) async => []);
    when(mockFlashcardLocalDataSource.getFlashcardsByLesson('test_lesson')).thenAnswer((_) async => []);

    // act
    final result = await unitOfWork.transaction<String>(() async {
      await mockContentLocalDataSource.getSubjects('test_user');
      await mockFlashcardLocalDataSource.getFlashcardsByLesson('test_lesson');
      return 'Success';
    });

    // assert
    expect(result, 'Success');
    verify(mockContentLocalDataSource.setTransaction(any)).called(2); // Set and clear
    verify(mockContentLocalDataSource.getSubjects('test_user')).called(1);
    verify(mockFlashcardLocalDataSource.setTransaction(any)).called(2); // Set and clear
    verify(mockFlashcardLocalDataSource.getFlashcardsByLesson('test_lesson')).called(1);
  });

  test('transaction should rollback on error', () async {
    // arrange
    when(mockDatabase.transaction<String>(any, exclusive: anyNamed('exclusive')))
        .thenAnswer((invocation) async {
      final action = invocation.positionalArguments[0] as Future<String> Function(Transaction);
      return await action(mockTransaction);
    });

    when(mockContentLocalDataSource.getSubjects('test_user'))
        .thenThrow(Exception('Test error'));

    // act & assert
    expect(
      () async => await unitOfWork.transaction<String>(() async {
        await mockContentLocalDataSource.getSubjects('test_user');
        return 'Success';
      }),
      throwsA(isA<Exception>()),
    );

    // Verify transaction was set and cleared even on error
    verify(mockContentLocalDataSource.setTransaction(mockTransaction)).called(1);
    verify(mockContentLocalDataSource.setTransaction(null)).called(1);
    verify(mockFlashcardLocalDataSource.setTransaction(mockTransaction)).called(1);
    verify(mockFlashcardLocalDataSource.setTransaction(null)).called(1);
  });
}