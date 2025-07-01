// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Topic {
  String get name => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get proficiency => throw _privateConstructorUsedError;
  int get lessonCount => throw _privateConstructorUsedError;
  DateTime get lastStudied => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopicCopyWith<Topic> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopicCopyWith<$Res> {
  factory $TopicCopyWith(Topic value, $Res Function(Topic) then) =
      _$TopicCopyWithImpl<$Res, Topic>;
  @useResult
  $Res call(
      {String name,
      String subjectName,
      String userId,
      double proficiency,
      int lessonCount,
      DateTime lastStudied,
      DateTime createdAt});
}

/// @nodoc
class _$TopicCopyWithImpl<$Res, $Val extends Topic>
    implements $TopicCopyWith<$Res> {
  _$TopicCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? subjectName = null,
    Object? userId = null,
    Object? proficiency = null,
    Object? lessonCount = null,
    Object? lastStudied = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
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
abstract class _$$TopicImplCopyWith<$Res> implements $TopicCopyWith<$Res> {
  factory _$$TopicImplCopyWith(
          _$TopicImpl value, $Res Function(_$TopicImpl) then) =
      __$$TopicImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String subjectName,
      String userId,
      double proficiency,
      int lessonCount,
      DateTime lastStudied,
      DateTime createdAt});
}

/// @nodoc
class __$$TopicImplCopyWithImpl<$Res>
    extends _$TopicCopyWithImpl<$Res, _$TopicImpl>
    implements _$$TopicImplCopyWith<$Res> {
  __$$TopicImplCopyWithImpl(
      _$TopicImpl _value, $Res Function(_$TopicImpl) _then)
      : super(_value, _then);

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? subjectName = null,
    Object? userId = null,
    Object? proficiency = null,
    Object? lessonCount = null,
    Object? lastStudied = null,
    Object? createdAt = null,
  }) {
    return _then(_$TopicImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
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

class _$TopicImpl extends _Topic {
  const _$TopicImpl(
      {required this.name,
      required this.subjectName,
      required this.userId,
      required this.proficiency,
      required this.lessonCount,
      required this.lastStudied,
      required this.createdAt})
      : super._();

  @override
  final String name;
  @override
  final String subjectName;
  @override
  final String userId;
  @override
  final double proficiency;
  @override
  final int lessonCount;
  @override
  final DateTime lastStudied;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Topic(name: $name, subjectName: $subjectName, userId: $userId, proficiency: $proficiency, lessonCount: $lessonCount, lastStudied: $lastStudied, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopicImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.proficiency, proficiency) ||
                other.proficiency == proficiency) &&
            (identical(other.lessonCount, lessonCount) ||
                other.lessonCount == lessonCount) &&
            (identical(other.lastStudied, lastStudied) ||
                other.lastStudied == lastStudied) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, subjectName, userId,
      proficiency, lessonCount, lastStudied, createdAt);

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopicImplCopyWith<_$TopicImpl> get copyWith =>
      __$$TopicImplCopyWithImpl<_$TopicImpl>(this, _$identity);
}

abstract class _Topic extends Topic {
  const factory _Topic(
      {required final String name,
      required final String subjectName,
      required final String userId,
      required final double proficiency,
      required final int lessonCount,
      required final DateTime lastStudied,
      required final DateTime createdAt}) = _$TopicImpl;
  const _Topic._() : super._();

  @override
  String get name;
  @override
  String get subjectName;
  @override
  String get userId;
  @override
  double get proficiency;
  @override
  int get lessonCount;
  @override
  DateTime get lastStudied;
  @override
  DateTime get createdAt;

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopicImplCopyWith<_$TopicImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
