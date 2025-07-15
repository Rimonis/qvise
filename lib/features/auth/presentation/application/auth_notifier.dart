// lib/features/auth/presentation/application/auth_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/auth/domain/usecases/sign_in_with_email_password.dart';
import 'package:qvise/features/auth/domain/usecases/sign_in_with_google.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInWithEmailPassword _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;

  AuthNotifier(this._signInWithEmail, this._signInWithGoogle)
      : super(const AuthState.initial());

  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState.loading();
    final result = await _signInWithEmail(email, password);

    result.fold(
      (AppFailure failure) => state = AuthState.error(failure),
      (user) => state = AuthState.authenticated(user),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    final result = await _signInWithGoogle();

    result.fold(
      (AppFailure failure) => state = AuthState.error(failure),
      (user) => state = AuthState.authenticated(user),
    );
  }
}
