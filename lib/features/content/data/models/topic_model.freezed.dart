// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TopicModel _$TopicModelFromJson(Map<String, dynamic> json) {
  return _TopicModel.fromJson(json);
}

/// @nodoc
mixin _$TopicModel {
  String get name => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get proficiency => throw _privateConstructorUsedError;
  int get lessonCount => throw _privateConstructorUsedError;
  DateTime get lastStudied => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this TopicModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopicModelCopyWith<TopicModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopicModelCopyWith<$Res> {
  factory $TopicModelCopyWith(
          TopicModel value, $Res Function(TopicModel) then) =
      _$TopicModelCopyWithImpl<$Res, TopicModel>;
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
class _$TopicModelCopyWithImpl<$Res, $Val extends TopicModel>
    implements $TopicModelCopyWith<$Res> {
  _$TopicModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopicModel
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
abstract class _$$TopicModelImplCopyWith<$Res>
    implements $TopicModelCopyWith<$Res> {
  factory _$$TopicModelImplCopyWith(
          _$TopicModelImpl value, $Res Function(_$TopicModelImpl) then) =
      __$$TopicModelImplCopyWithImpl<$Res>;
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
class __$$TopicModelImplCopyWithImpl<$Res>
    extends _$TopicModelCopyWithImpl<$Res, _$TopicModelImpl>
    implements _$$TopicModelImplCopyWith<$Res> {
  __$$TopicModelImplCopyWithImpl(
      _$TopicModelImpl _value, $Res Function(_$TopicModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TopicModel
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
    return _then(_$TopicModelImpl(
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
@JsonSerializable()
class _$TopicModelImpl extends _TopicModel {
  const _$TopicModelImpl(
      {required this.name,
      required this.subjectName,
      required this.userId,
      required this.proficiency,
      required this.lessonCount,
      required this.lastStudied,
      required this.createdAt})
      : super._();

  factory _$TopicModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopicModelImplFromJson(json);

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
    return 'TopicModel(name: $name, subjectName: $subjectName, userId: $userId, proficiency: $proficiency, lessonCount: $lessonCount, lastStudied: $lastStudied, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopicModelImpl &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, subjectName, userId,
      proficiency, lessonCount, lastStudied, createdAt);

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopicModelImplCopyWith<_$TopicModelImpl> get copyWith =>
      __$$TopicModelImplCopyWithImpl<_$TopicModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopicModelImplToJson(
      this,
    );
  }
}

abstract class _TopicModel extends TopicModel {
  const factory _TopicModel(
      {required final String name,
      required final String subjectName,
      required final String userId,
      required final double proficiency,
      required final int lessonCount,
      required final DateTime lastStudied,
      required final DateTime createdAt}) = _$TopicModelImpl;
  const _TopicModel._() : super._();

  factory _TopicModel.fromJson(Map<String, dynamic> json) =
      _$TopicModelImpl.fromJson;

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

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopicModelImplCopyWith<_$TopicModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
