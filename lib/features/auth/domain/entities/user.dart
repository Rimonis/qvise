import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    @Default('free') String subscriptionTier,
    @Default(false) bool isEmailVerified, // New field
  }) = _User;
}