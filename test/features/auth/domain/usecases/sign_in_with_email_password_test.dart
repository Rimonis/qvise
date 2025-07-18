// test/features/auth/domain/usecases/sign_in_with_email_password_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/features/auth/domain/usecases/sign_in_with_email_password.dart';
import 'package:qvise/features/auth/domain/entities/user.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late SignInWithEmailPassword usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInWithEmailPassword(mockAuthRepository);
  });

  final tUser = User(id: '1', email: 'test@test.com');

  test('should sign in a user from the repository', () async {
    // arrange
    when(mockAuthRepository.signInWithEmailPassword(any, any))
        .thenAnswer((_) async => Right(tUser));
    // act
    final result = await usecase('test@test.com', 'password');
    // assert
    expect(result, Right(tUser));
    verify(mockAuthRepository.signInWithEmailPassword('test@test.com', 'password'));
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
