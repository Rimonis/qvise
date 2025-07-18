// lib/core/providers/providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:qvise/firebase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_password.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up_with_email_password.dart';
import '../../features/auth/domain/usecases/send_email_verification.dart';
import '../../features/auth/domain/usecases/check_email_verification.dart';
import '../../features/auth/domain/usecases/reset_password.dart';

// Export the new data providers file for easy access
export '../data/providers/data_providers.dart';

part 'providers.g.dart';

// Core
@Riverpod(keepAlive: true)
InternetConnectionChecker internetConnectionChecker(Ref ref) {
  return InternetConnectionChecker();
}

// Firebase
@Riverpod(keepAlive: true)
Future<void> firebaseInitialization(Ref ref) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
}

@Riverpod(keepAlive: true)
firebase_auth.FirebaseAuth firebaseAuth(Ref ref) {
  return firebase_auth.FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(Ref ref) {
  return GoogleSignIn();
}

@Riverpod(keepAlive: true)
Stream<firebase_auth.User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

@Riverpod(keepAlive: true)
AsyncValue<firebase_auth.User?> currentUser(Ref ref) {
  return ref.watch(authStateChangesProvider);
}

@Riverpod()
bool isAuthenticated(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user.valueOrNull != null;
}

// Database
@Riverpod(keepAlive: true)
Future<AuthLocalDataSource> authLocalDataSource(Ref ref) async {
  final database = await AuthLocalDataSourceImpl.createDatabase();
  return AuthLocalDataSourceImpl(database: database);
}

// Data sources
@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

// Repositories
@Riverpod(keepAlive: true)
Future<AuthRepository> authRepository(Ref ref) async {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: await ref.watch(authLocalDataSourceProvider.future),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
  );
}

// Use cases
@Riverpod(keepAlive: true)
Future<GetCurrentUser> getCurrentUser(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return GetCurrentUser(repository);
}

@Riverpod(keepAlive: true)
Future<SignInWithEmailPassword> signInWithEmailPassword(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return SignInWithEmailPassword(repository);
}

@Riverpod(keepAlive: true)
Future<SignUpWithEmailPassword> signUpWithEmailPassword(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return SignUpWithEmailPassword(repository);
}

@Riverpod(keepAlive: true)
Future<SignInWithGoogle> signInWithGoogle(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return SignInWithGoogle(repository);
}

@Riverpod(keepAlive: true)
Future<SignOut> signOut(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return SignOut(repository);
}

// Email verification use cases
@Riverpod(keepAlive: true)
Future<SendEmailVerification> sendEmailVerification(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return SendEmailVerification(repository);
}

@Riverpod(keepAlive: true)
Future<CheckEmailVerification> checkEmailVerification(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return CheckEmailVerification(repository);
}

// Password reset use case
@Riverpod(keepAlive: true)
Future<ResetPassword> resetPassword(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return ResetPassword(repository);
}
