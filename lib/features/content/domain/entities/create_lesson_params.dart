import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_lesson_params.freezed.dart';

@freezed
class CreateLessonParams with _$CreateLessonParams {
  const factory CreateLessonParams({
    required String subjectName,
    required String topicName,
    String? lessonTitle,
    required bool isNewSubject,
    required bool isNewTopic,
  }) = _CreateLessonParams;
}