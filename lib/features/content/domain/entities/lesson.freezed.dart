// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Lesson {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  String get topicName => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // When lesson was created
  DateTime? get lockedAt =>
      throw _privateConstructorUsedError; // When lesson was locked (null if unlocked)
  DateTime get nextReviewDate => throw _privateConstructorUsedError;
  DateTime? get lastReviewedAt => throw _privateConstructorUsedError;
  int get reviewStage => throw _privateConstructorUsedError;
  double get proficiency => throw _privateConstructorUsedError;
  bool get isLocked =>
      throw _privateConstructorUsedError; // Whether lesson is locked
  bool get isSynced => throw _privateConstructorUsedError;
  int get flashcardCount =>
      throw _privateConstructorUsedError; // Number of flashcards
  int get fileCount => throw _privateConstructorUsedError; // Number of files
  int get noteCount => throw _privateConstructorUsedError;

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LessonCopyWith<Lesson> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LessonCopyWith<$Res> {
  factory $LessonCopyWith(Lesson value, $Res Function(Lesson) then) =
      _$LessonCopyWithImpl<$Res, Lesson>;
  @useResult
  $Res call({
    String id,
    String userId,
    String subjectName,
    String topicName,
    String? title,
    DateTime createdAt,
    DateTime? lockedAt,
    DateTime nextReviewDate,
    DateTime? lastReviewedAt,
    int reviewStage,
    double proficiency,
    bool isLocked,
    bool isSynced,
    int flashcardCount,
    int fileCount,
    int noteCount,
  });
}

/// @nodoc
class _$LessonCopyWithImpl<$Res, $Val extends Lesson>
    implements $LessonCopyWith<$Res> {
  _$LessonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? subjectName = null,
    Object? topicName = null,
    Object? title = freezed,
    Object? createdAt = null,
    Object? lockedAt = freezed,
    Object? nextReviewDate = null,
    Object? lastReviewedAt = freezed,
    Object? reviewStage = null,
    Object? proficiency = null,
    Object? isLocked = null,
    Object? isSynced = null,
    Object? flashcardCount = null,
    Object? fileCount = null,
    Object? noteCount = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
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
            title:
                freezed == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            lockedAt:
                freezed == lockedAt
                    ? _value.lockedAt
                    : lockedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            nextReviewDate:
                null == nextReviewDate
                    ? _value.nextReviewDate
                    : nextReviewDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            lastReviewedAt:
                freezed == lastReviewedAt
                    ? _value.lastReviewedAt
                    : lastReviewedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            reviewStage:
                null == reviewStage
                    ? _value.reviewStage
                    : reviewStage // ignore: cast_nullable_to_non_nullable
                        as int,
            proficiency:
                null == proficiency
                    ? _value.proficiency
                    : proficiency // ignore: cast_nullable_to_non_nullable
                        as double,
            isLocked:
                null == isLocked
                    ? _value.isLocked
                    : isLocked // ignore: cast_nullable_to_non_nullable
                        as bool,
            isSynced:
                null == isSynced
                    ? _value.isSynced
                    : isSynced // ignore: cast_nullable_to_non_nullable
                        as bool,
            flashcardCount:
                null == flashcardCount
                    ? _value.flashcardCount
                    : flashcardCount // ignore: cast_nullable_to_non_nullable
                        as int,
            fileCount:
                null == fileCount
                    ? _value.fileCount
                    : fileCount // ignore: cast_nullable_to_non_nullable
                        as int,
            noteCount:
                null == noteCount
                    ? _value.noteCount
                    : noteCount // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LessonImplCopyWith<$Res> implements $LessonCopyWith<$Res> {
  factory _$$LessonImplCopyWith(
    _$LessonImpl value,
    $Res Function(_$LessonImpl) then,
  ) = __$$LessonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String subjectName,
    String topicName,
    String? title,
    DateTime createdAt,
    DateTime? lockedAt,
    DateTime nextReviewDate,
    DateTime? lastReviewedAt,
    int reviewStage,
    double proficiency,
    bool isLocked,
    bool isSynced,
    int flashcardCount,
    int fileCount,
    int noteCount,
  });
}

/// @nodoc
class __$$LessonImplCopyWithImpl<$Res>
    extends _$LessonCopyWithImpl<$Res, _$LessonImpl>
    implements _$$LessonImplCopyWith<$Res> {
  __$$LessonImplCopyWithImpl(
    _$LessonImpl _value,
    $Res Function(_$LessonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? subjectName = null,
    Object? topicName = null,
    Object? title = freezed,
    Object? createdAt = null,
    Object? lockedAt = freezed,
    Object? nextReviewDate = null,
    Object? lastReviewedAt = freezed,
    Object? reviewStage = null,
    Object? proficiency = null,
    Object? isLocked = null,
    Object? isSynced = null,
    Object? flashcardCount = null,
    Object? fileCount = null,
    Object? noteCount = null,
  }) {
    return _then(
      _$LessonImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
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
        title:
            freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        lockedAt:
            freezed == lockedAt
                ? _value.lockedAt
                : lockedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        nextReviewDate:
            null == nextReviewDate
                ? _value.nextReviewDate
                : nextReviewDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        lastReviewedAt:
            freezed == lastReviewedAt
                ? _value.lastReviewedAt
                : lastReviewedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        reviewStage:
            null == reviewStage
                ? _value.reviewStage
                : reviewStage // ignore: cast_nullable_to_non_nullable
                    as int,
        proficiency:
            null == proficiency
                ? _value.proficiency
                : proficiency // ignore: cast_nullable_to_non_nullable
                    as double,
        isLocked:
            null == isLocked
                ? _value.isLocked
                : isLocked // ignore: cast_nullable_to_non_nullable
                    as bool,
        isSynced:
            null == isSynced
                ? _value.isSynced
                : isSynced // ignore: cast_nullable_to_non_nullable
                    as bool,
        flashcardCount:
            null == flashcardCount
                ? _value.flashcardCount
                : flashcardCount // ignore: cast_nullable_to_non_nullable
                    as int,
        fileCount:
            null == fileCount
                ? _value.fileCount
                : fileCount // ignore: cast_nullable_to_non_nullable
                    as int,
        noteCount:
            null == noteCount
                ? _value.noteCount
                : noteCount // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

class _$LessonImpl extends _Lesson {
  const _$LessonImpl({
    required this.id,
    required this.userId,
    required this.subjectName,
    required this.topicName,
    this.title,
    required this.createdAt,
    this.lockedAt,
    required this.nextReviewDate,
    this.lastReviewedAt,
    required this.reviewStage,
    required this.proficiency,
    this.isLocked = false,
    this.isSynced = false,
    this.flashcardCount = 0,
    this.fileCount = 0,
    this.noteCount = 0,
  }) : super._();

  @override
  final String id;
  @override
  final String userId;
  @override
  final String subjectName;
  @override
  final String topicName;
  @override
  final String? title;
  @override
  final DateTime createdAt;
  // When lesson was created
  @override
  final DateTime? lockedAt;
  // When lesson was locked (null if unlocked)
  @override
  final DateTime nextReviewDate;
  @override
  final DateTime? lastReviewedAt;
  @override
  final int reviewStage;
  @override
  final double proficiency;
  @override
  @JsonKey()
  final bool isLocked;
  // Whether lesson is locked
  @override
  @JsonKey()
  final bool isSynced;
  @override
  @JsonKey()
  final int flashcardCount;
  // Number of flashcards
  @override
  @JsonKey()
  final int fileCount;
  // Number of files
  @override
  @JsonKey()
  final int noteCount;

  @override
  String toString() {
    return 'Lesson(id: $id, userId: $userId, subjectName: $subjectName, topicName: $topicName, title: $title, createdAt: $createdAt, lockedAt: $lockedAt, nextReviewDate: $nextReviewDate, lastReviewedAt: $lastReviewedAt, reviewStage: $reviewStage, proficiency: $proficiency, isLocked: $isLocked, isSynced: $isSynced, flashcardCount: $flashcardCount, fileCount: $fileCount, noteCount: $noteCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LessonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.topicName, topicName) ||
                other.topicName == topicName) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lockedAt, lockedAt) ||
                other.lockedAt == lockedAt) &&
            (identical(other.nextReviewDate, nextReviewDate) ||
                other.nextReviewDate == nextReviewDate) &&
            (identical(other.lastReviewedAt, lastReviewedAt) ||
                other.lastReviewedAt == lastReviewedAt) &&
            (identical(other.reviewStage, reviewStage) ||
                other.reviewStage == reviewStage) &&
            (identical(other.proficiency, proficiency) ||
                other.proficiency == proficiency) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.flashcardCount, flashcardCount) ||
                other.flashcardCount == flashcardCount) &&
            (identical(other.fileCount, fileCount) ||
                other.fileCount == fileCount) &&
            (identical(other.noteCount, noteCount) ||
                other.noteCount == noteCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    subjectName,
    topicName,
    title,
    createdAt,
    lockedAt,
    nextReviewDate,
    lastReviewedAt,
    reviewStage,
    proficiency,
    isLocked,
    isSynced,
    flashcardCount,
    fileCount,
    noteCount,
  );

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LessonImplCopyWith<_$LessonImpl> get copyWith =>
      __$$LessonImplCopyWithImpl<_$LessonImpl>(this, _$identity);
}

abstract class _Lesson extends Lesson {
  const factory _Lesson({
    required final String id,
    required final String userId,
    required final String subjectName,
    required final String topicName,
    final String? title,
    required final DateTime createdAt,
    final DateTime? lockedAt,
    required final DateTime nextReviewDate,
    final DateTime? lastReviewedAt,
    required final int reviewStage,
    required final double proficiency,
    final bool isLocked,
    final bool isSynced,
    final int flashcardCount,
    final int fileCount,
    final int noteCount,
  }) = _$LessonImpl;
  const _Lesson._() : super._();

  @override
  String get id;
  @override
  String get userId;
  @override
  String get subjectName;
  @override
  String get topicName;
  @override
  String? get title;
  @override
  DateTime get createdAt; // When lesson was created
  @override
  DateTime? get lockedAt; // When lesson was locked (null if unlocked)
  @override
  DateTime get nextReviewDate;
  @override
  DateTime? get lastReviewedAt;
  @override
  int get reviewStage;
  @override
  double get proficiency;
  @override
  bool get isLocked; // Whether lesson is locked
  @override
  bool get isSynced;
  @override
  int get flashcardCount; // Number of flashcards
  @override
  int get fileCount; // Number of files
  @override
  int get noteCount;

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LessonImplCopyWith<_$LessonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
