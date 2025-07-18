// test/core/utils/password_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qvise/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    test('validate should return null for a valid password', () {
      expect(PasswordValidator.validate('Password123!'), isNull);
    });

    test('validate should return error for short password', () {
      expect(PasswordValidator.validate('Pass1!'), 'Password must be at least 8 characters');
    });

    test('validate should return error for missing uppercase letter', () {
      expect(PasswordValidator.validate('password123!'), 'Password must contain at least one uppercase letter');
    });

    test('validate should return error for missing lowercase letter', () {
      expect(PasswordValidator.validate('PASSWORD123!'), 'Password must contain at least one lowercase letter');
    });

    test('validate should return error for missing number', () {
      expect(PasswordValidator.validate('Password!'), 'Password must contain at least one number');
    });

    test('validate should return error for missing special character', () {
      expect(PasswordValidator.validate('Password123'), 'Password must contain at least one special character');
    });
  });
}
