// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subject.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Subject {
  String get name => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get proficiency => throw _privateConstructorUsedError;
  int get lessonCount => throw _privateConstructorUsedError;
  int get topicCount => throw _privateConstructorUsedError;
  DateTime get lastStudied => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubjectCopyWith<Subject> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubjectCopyWith<$Res> {
  factory $SubjectCopyWith(Subject value, $Res Function(Subject) then) =
      _$SubjectCopyWithImpl<$Res, Subject>;
  @useResult
  $Res call(
      {String name,
      String userId,
      double proficiency,
      int lessonCount,
      int topicCount,
      DateTime lastStudied,
      DateTime createdAt});
}

/// @nodoc
class _$SubjectCopyWithImpl<$Res, $Val extends Subject>
    implements $SubjectCopyWith<$Res> {
  _$SubjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? userId = null,
    Object? proficiency = null,
    Object? lessonCount = null,
    Object? topicCount = null,
    Object? lastStudied = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      proficiency: null == proficiency
          ? _value.proficiency
          : proficiency // ignore: cast_nullable_to_non_nullable
              as double,
      lessonCount: null == lessonCount
          ? _value.lessonCount
          : lessonCount // ignore: cast_nullable_to_non_nullable
              as int,
      topicCount: null == topicCount
          ? _value.topicCount
          : topicCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastStudied: null == lastStudied
          ? _value.lastStudied
          : lastStudied // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubjectImplCopyWith<$Res> implements $SubjectCopyWith<$Res> {
  factory _$$SubjectImplCopyWith(
          _$SubjectImpl value, $Res Function(_$SubjectImpl) then) =
      __$$SubjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String userId,
      double proficiency,
      int lessonCount,
      int topicCount,
      DateTime lastStudied,
      DateTime createdAt});
}

/// @nodoc
class __$$SubjectImplCopyWithImpl<$Res>
    extends _$SubjectCopyWithImpl<$Res, _$SubjectImpl>
    implements _$$SubjectImplCopyWith<$Res> {
  __$$SubjectImplCopyWithImpl(
      _$SubjectImpl _value, $Res Function(_$SubjectImpl) _then)
      : super(_value, _then);

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? userId = null,
    Object? proficiency = null,
    Object? lessonCount = null,
    Object? topicCount = null,
    Object? lastStudied = null,
    Object? createdAt = null,
  }) {
    return _then(_$SubjectImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      proficiency: null == proficiency
          ? _value.proficiency
          : proficiency // ignore: cast_nullable_to_non_nullable
              as double,
      lessonCount: null == lessonCount
          ? _value.lessonCount
          : lessonCount // ignore: cast_nullable_to_non_nullable
              as int,
      topicCount: null == topicCount
          ? _value.topicCount
          : topicCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastStudied: null == lastStudied
          ? _value.lastStudied
          : lastStudied // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$SubjectImpl extends _Subject {
  const _$SubjectImpl(
      {required this.name,
      required this.userId,
      required this.proficiency,
      required this.lessonCount,
      required this.topicCount,
      required this.lastStudied,
      required this.createdAt})
      : super._();

  @override
  final String name;
  @override
  final String userId;
  @override
  final double proficiency;
  @override
  final int lessonCount;
  @override
  final int topicCount;
  @override
  final DateTime lastStudied;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Subject(name: $name, userId: $userId, proficiency: $proficiency, lessonCount: $lessonCount, topicCount: $topicCount, lastStudied: $lastStudied, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubjectImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.proficiency, proficiency) ||
                other.proficiency == proficiency) &&
            (identical(other.lessonCount, lessonCount) ||
                other.lessonCount == lessonCount) &&
            (identical(other.topicCount, topicCount) ||
                other.topicCount == topicCount) &&
            (identical(other.lastStudied, lastStudied) ||
                other.lastStudied == lastStudied) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, userId, proficiency,
      lessonCount, topicCount, lastStudied, createdAt);

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubjectImplCopyWith<_$SubjectImpl> get copyWith =>
      __$$SubjectImplCopyWithImpl<_$SubjectImpl>(this, _$identity);
}

abstract class _Subject extends Subject {
  const factory _Subject(
      {required final String name,
      required final String userId,
      required final double proficiency,
      required final int lessonCount,
      required final int topicCount,
      required final DateTime lastStudied,
      required final DateTime createdAt}) = _$SubjectImpl;
  const _Subject._() : super._();

  @override
  String get name;
  @override
  String get userId;
  @override
  double get proficiency;
  @override
  int get lessonCount;
  @override
  int get topicCount;
  @override
  DateTime get lastStudied;
  @override
  DateTime get createdAt;

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubjectImplCopyWith<_$SubjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
