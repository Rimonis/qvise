// lib/core/providers/providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:qvise/core/data/providers/data_providers.dart';
import 'package:qvise/core/sync/data/datasources/conflict_local_datasource.dart';
import 'package:qvise/core/sync/services/conflict_resolver.dart';
import 'package:qvise/core/sync/services/sync_service.dart';
import 'package:qvise/features/content/presentation/providers/content_providers.dart';
import 'package:qvise/features/flashcards/shared/presentation/providers/flashcard_providers.dart';
import 'package:qvise/features/notes/presentation/providers/note_providers.dart';
import 'package:qvise/firebase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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


part 'providers.g.dart';

// Core
@Riverpod(keepAlive: true)
InternetConnectionChecker internetConnectionChecker(Ref ref) {
  return InternetConnectionChecker();
}

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) {
  return SharedPreferences.getInstance();
}

// Firebase
@Riverpod(keepAlive: true)
Future<void> firebaseInitialization(Ref ref) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

// Data sources
@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

@Riverpod(keepAlive: true)
AuthLocalDataSource authLocalDataSource(Ref ref) {
  return AuthLocalDataSourceImpl(); // Remove database parameter
}

// Repositories
@Riverpod(keepAlive: true)
Future<AuthRepository> authRepository(Ref ref) async {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider), // FIX: Removed .future
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

@Riverpod(keepAlive: true)
Future<ResetPassword> resetPassword(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return ResetPassword(repository);
}

// Sync Providers
@Riverpod(keepAlive: true)
ConflictLocalDataSource conflictDataSource(Ref ref) {
  return ConflictLocalDataSourceImpl();
}

@Riverpod(keepAlive: true)
Future<SyncService> syncService(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final user = ref.watch(currentUserProvider).valueOrNull;

  return SyncService(
    unitOfWork: ref.watch(unitOfWorkProvider),
    remoteContent: ref.watch(contentRemoteDataSourceProvider),
    remoteFlashcard: ref.watch(flashcardRemoteDataSourceProvider),
    remoteNote: ref.watch(noteRemoteDataSourceProvider), // FIX: Added missing remoteNote parameter
    conflictDataSource: ref.watch(conflictDataSourceProvider),
    conflictResolver: ref.watch(conflictResolverProvider),
    prefs: prefs,
    userId: user?.uid ?? '',
  );
}

@Riverpod(keepAlive: true)
ConflictResolver conflictResolver(Ref ref) {
  return ConflictResolver(
    unitOfWork: ref.watch(unitOfWorkProvider),
    conflictDataSource: ref.watch(conflictDataSourceProvider),
  );
}