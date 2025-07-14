// lib/features/auth/data/datasources/auth_remote_data_source_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Stream<firebase_auth.User?> authStateChanges() {
    return firebaseAuth.authStateChanges();
  }

  @override
  Future<firebase_auth.User?> getCurrentUser() async {
    return firebaseAuth.currentUser;
  }

  @override
  Future<UserModel> signInWithEmailPassword(String email, String password) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign in failed',
      );
    }
    
    return UserModel.fromFirebase(credential.user!);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'aborted-by-user',
        message: 'Google sign in was cancelled',
      );
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await firebaseAuth.signInWithCredential(credential);
    
    if (userCredential.user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Google sign in failed',
      );
    }
    
    return UserModel.fromFirebase(userCredential.user!);
  }

  @override
  Future<UserModel> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = firebase_auth.OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await firebaseAuth.signInWithCredential(oauthCredential);
    
    if (userCredential.user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Apple sign in failed',
      );
    }
    
    return UserModel.fromFirebase(userCredential.user!);
  }

  @override
  Future<UserModel> signUpWithEmailPassword(String email, String password, String displayName) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'registration-failed',
        message: 'Registration failed',
      );
    }

    // Update display name
    await credential.user!.updateDisplayName(displayName);
    
    return UserModel.fromFirebase(credential.user!);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      firebaseAuth.signOut(),
      googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    // Reauthenticate first
    await reauthenticate(currentPassword);
    
    // Change password
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    await user.sendEmailVerification();
  }

  @override
  Future<bool> checkEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    await user.reload();
    return user.emailVerified;
  }

  @override
  Future<void> reloadUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    await user.reload();
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    await user.updateProfile(
      displayName: displayName,
      photoURL: photoUrl,
    );
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    await user.updateEmail(newEmail);
  }

  @override
  Future<void> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    await user.delete();
  }

  @override
  Future<void> reauthenticate(String password) async {
    final user = firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> signOutFromAllDevices() async {
    // Note: Firebase doesn't have a direct "sign out from all devices" method
    // This would typically involve revoking tokens on the server side
    // For now, we'll just sign out from this device
    await signOut();
  }
}
