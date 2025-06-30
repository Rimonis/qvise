// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_lesson_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CreateLessonParams {
  String get subjectName => throw _privateConstructorUsedError;
  String get topicName => throw _privateConstructorUsedError;
  String? get lessonTitle => throw _privateConstructorUsedError;
  bool get isNewSubject => throw _privateConstructorUsedError;
  bool get isNewTopic => throw _privateConstructorUsedError;

  /// Create a copy of CreateLessonParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateLessonParamsCopyWith<CreateLessonParams> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateLessonParamsCopyWith<$Res> {
  factory $CreateLessonParamsCopyWith(
    CreateLessonParams value,
    $Res Function(CreateLessonParams) then,
  ) = _$CreateLessonParamsCopyWithImpl<$Res, CreateLessonParams>;
  @useResult
  $Res call({
    String subjectName,
    String topicName,
    String? lessonTitle,
    bool isNewSubject,
    bool isNewTopic,
  });
}

/// @nodoc
class _$CreateLessonParamsCopyWithImpl<$Res, $Val extends CreateLessonParams>
    implements $CreateLessonParamsCopyWith<$Res> {
  _$CreateLessonParamsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateLessonParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subjectName = null,
    Object? topicName = null,
    Object? lessonTitle = freezed,
    Object? isNewSubject = null,
    Object? isNewTopic = null,
  }) {
    return _then(
      _value.copyWith(
            subjectName:
                null == subjectName
                    ? _value.subjectName
                    : subjectName // ignore: cast_nullable_to_non_nullable
                        as String,
            topicName:
                null == topicName
                    ? _value.topicName
                    : topicName // ignore: cast_nullable_to_non_nullable
                        as String,
            lessonTitle:
                freezed == lessonTitle
                    ? _value.lessonTitle
                    : lessonTitle // ignore: cast_nullable_to_non_nullable
                        as String?,
            isNewSubject:
                null == isNewSubject
                    ? _value.isNewSubject
                    : isNewSubject // ignore: cast_nullable_to_non_nullable
                        as bool,
            isNewTopic:
                null == isNewTopic
                    ? _value.isNewTopic
                    : isNewTopic // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateLessonParamsImplCopyWith<$Res>
    implements $CreateLessonParamsCopyWith<$Res> {
  factory _$$CreateLessonParamsImplCopyWith(
    _$CreateLessonParamsImpl value,
    $Res Function(_$CreateLessonParamsImpl) then,
  ) = __$$CreateLessonParamsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String subjectName,
    String topicName,
    String? lessonTitle,
    bool isNewSubject,
    bool isNewTopic,
  });
}

/// @nodoc
class __$$CreateLessonParamsImplCopyWithImpl<$Res>
    extends _$CreateLessonParamsCopyWithImpl<$Res, _$CreateLessonParamsImpl>
    implements _$$CreateLessonParamsImplCopyWith<$Res> {
  __$$CreateLessonParamsImplCopyWithImpl(
    _$CreateLessonParamsImpl _value,
    $Res Function(_$CreateLessonParamsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateLessonParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subjectName = null,
    Object? topicName = null,
    Object? lessonTitle = freezed,
    Object? isNewSubject = null,
    Object? isNewTopic = null,
  }) {
    return _then(
      _$CreateLessonParamsImpl(
        subjectName:
            null == subjectName
                ? _value.subjectName
                : subjectName // ignore: cast_nullable_to_non_nullable
                    as String,
        topicName:
            null == topicName
                ? _value.topicName
                : topicName // ignore: cast_nullable_to_non_nullable
                    as String,
        lessonTitle:
            freezed == lessonTitle
                ? _value.lessonTitle
                : lessonTitle // ignore: cast_nullable_to_non_nullable
                    as String?,
        isNewSubject:
            null == isNewSubject
                ? _value.isNewSubject
                : isNewSubject // ignore: cast_nullable_to_non_nullable
                    as bool,
        isNewTopic:
            null == isNewTopic
                ? _value.isNewTopic
                : isNewTopic // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$CreateLessonParamsImpl implements _CreateLessonParams {
  const _$CreateLessonParamsImpl({
    required this.subjectName,
    required this.topicName,
    this.lessonTitle,
    required this.isNewSubject,
    required this.isNewTopic,
  });

  @override
  final String subjectName;
  @override
  final String topicName;
  @override
  final String? lessonTitle;
  @override
  final bool isNewSubject;
  @override
  final bool isNewTopic;

  @override
  String toString() {
    return 'CreateLessonParams(subjectName: $subjectName, topicName: $topicName, lessonTitle: $lessonTitle, isNewSubject: $isNewSubject, isNewTopic: $isNewTopic)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateLessonParamsImpl &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.topicName, topicName) ||
                other.topicName == topicName) &&
            (identical(other.lessonTitle, lessonTitle) ||
                other.lessonTitle == lessonTitle) &&
            (identical(other.isNewSubject, isNewSubject) ||
                other.isNewSubject == isNewSubject) &&
            (identical(other.isNewTopic, isNewTopic) ||
                other.isNewTopic == isNewTopic));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    subjectName,
    topicName,
    lessonTitle,
    isNewSubject,
    isNewTopic,
  );

  /// Create a copy of CreateLessonParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateLessonParamsImplCopyWith<_$CreateLessonParamsImpl> get copyWith =>
      __$$CreateLessonParamsImplCopyWithImpl<_$CreateLessonParamsImpl>(
        this,
        _$identity,
      );
}

abstract class _CreateLessonParams implements CreateLessonParams {
  const factory _CreateLessonParams({
    required final String subjectName,
    required final String topicName,
    final String? lessonTitle,
    required final bool isNewSubject,
    required final bool isNewTopic,
  }) = _$CreateLessonParamsImpl;

  @override
  String get subjectName;
  @override
  String get topicName;
  @override
  String? get lessonTitle;
  @override
  bool get isNewSubject;
  @override
  bool get isNewTopic;

  /// Create a copy of CreateLessonParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateLessonParamsImplCopyWith<_$CreateLessonParamsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
