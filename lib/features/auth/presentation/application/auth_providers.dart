// lib/features/auth/presentation/application/auth_providers.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_state.dart';
import '../../domain/entities/user.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRemoteDataSource authRemoteDataSource(AuthRemoteDataSourceRef ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  StreamSubscription<User?>? _authStateSubscription;

  @override
  AuthState build() {
    _authStateSubscription?.cancel();
    _authStateSubscription =
        ref.watch(authRepositoryProvider).authStateChanges().listen(_onUserChanged);

    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });

    return const AuthState.initial();
  }

  void _onUserChanged(User? user) {
    if (user == null) {
      state = const AuthState.unauthenticated();
    } else {
      state = user.isEmailVerified
        ? AuthState.authenticated(user)
          : AuthState.emailNotVerified(user);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthState.loading();
    final result = await ref.read(authRepositoryProvider).signUpWithEmailPassword(email, password, displayName);
    result.fold(
      (error) => state = AuthState.error(error.userFriendlyMessage),
      (user) {
        // Listener will handle state change
      },
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    final result = await ref.read(authRepositoryProvider).signInWithEmailPassword(email, password);
    result.fold(
      (error) => state = AuthState.error(error.userFriendlyMessage),
      (user) {
        // Listener will handle state change
      },
    );
  }

  Future<void> googleSignIn() async {
    state = const AuthState.loading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    result.fold(
      (error) => state = AuthState.error(error.userFriendlyMessage),
      (user) {
        // Listener will handle state change
      },
    );
  }

  Future<void> doSignOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState.unauthenticated();
  }

  Future<void> doSendVerificationEmail() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await ref.read(firebaseAuthProvider).currentUser?.reload();
    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
    _onUserChanged(firebaseUser!= null? User.fromFirebase(firebaseUser) : null);
  }
}
