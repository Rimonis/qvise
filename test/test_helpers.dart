// test/test_helpers.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';

/// Custom matcher for Either types
class IsRight<L, R> extends Matcher {
  final Matcher? valueMatcher;
  
  const IsRight([this.valueMatcher]);
  
  @override
  bool matches(item, Map matchState) {
    if (item is! Either<L, R>) return false;
    if (!item.isRight()) return false;
    
    if (valueMatcher != null) {
      final rightValue = item.getOrElse(() => throw Exception('Should not happen'));
      return valueMatcher!.matches(rightValue, matchState);
    }
    
    return true;
  }
  
  @override
  Description describe(Description description) {
    if (valueMatcher != null) {
      return description.add('Right with value that ').addDescriptionOf(valueMatcher);
    }
    return description.add('Right');
  }
}

class IsLeft<L, R> extends Matcher {
  final Matcher? valueMatcher;
  
  const IsLeft([this.valueMatcher]);
  
  @override
  bool matches(item, Map matchState) {
    if (item is! Either<L, R>) return false;
    if (!item.isLeft()) return false;
    
    if (valueMatcher != null) {
      final leftValue = item.fold((l) => l, (r) => throw Exception('Should not happen'));
      return valueMatcher!.matches(leftValue, matchState);
    }
    
    return true;
  }
  
  @override
  Description describe(Description description) {
    if (valueMatcher != null) {
      return description.add('Left with value that ').addDescriptionOf(valueMatcher);
    }
    return description.add('Left');
  }
}

/// Convenience functions for testing Either values
Matcher isRight<L, R>([Matcher? valueMatcher]) => IsRight<L, R>(valueMatcher);
Matcher isLeft<L, R>([Matcher? valueMatcher]) => IsLeft<L, R>(valueMatcher);

/// Matcher for AppFailure
Matcher isAppFailure({FailureType? type, String? message}) {
  return predicate<AppFailure>(
    (failure) {
      if (type != null && failure.type != type) return false;
      if (message != null && !failure.message.contains(message)) return false;
      return true;
    },
    'AppFailure${type != null ? ' with type $type' : ''}${message != null ? ' containing "$message"' : ''}',
  );
}

/// Helper function to extract Right value for testing
R? getRight<L, R>(Either<L, R> either) {
  return either.fold((_) => null, (r) => r);
}

/// Helper function to extract Left value for testing
L? getLeft<L, R>(Either<L, R> either) {
  return either.fold((l) => l, (_) => null);
}