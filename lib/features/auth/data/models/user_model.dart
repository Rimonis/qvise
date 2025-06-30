import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    @Default('free') String subscriptionTier,
    @Default(false) bool isEmailVerified, // New field
  }) = _UserModel;

  const UserModel._();

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  // Updated fromFirebase method with email verification
  factory UserModel.fromFirebase(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      subscriptionTier: 'free',
      isEmailVerified: firebaseUser.emailVerified, // Include email verification status
    );
  }

  // Keep the old method for backward compatibility but make it safer
  factory UserModel.fromFirebaseMap(Map<String, dynamic> firebaseUser, String uid) {
    return UserModel(
      id: uid,
      email: firebaseUser['email']?.toString() ?? '',
      displayName: firebaseUser['displayName']?.toString(),
      photoUrl: firebaseUser['photoURL']?.toString(),
      subscriptionTier: 'free',
      isEmailVerified: firebaseUser['emailVerified'] == true,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      subscriptionTier: subscriptionTier,
      isEmailVerified: isEmailVerified, // Include in entity conversion
    );
  }
}