import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../domain/usecases/use_cases.dart';
import '../providers/auth_providers.dart';
import '../states/auth_state.dart';

class AuthViewModel extends Notifier<AuthState> {
  late final AuthUseCases _useCases;

  @override
  AuthState build() {
    _useCases = ref.watch(authUseCasesProvider);
    ref.listen(authStateChangesProvider, (previous, next) {
      if (state is AuthLoading) return;

      switch (next) {
        case AsyncData(:final value):
          state = value == null
              ? const AuthUnauthenticated()
              : AuthAuthenticated(value);
        case AsyncError(:final error):
          state = AuthFailure(error.toString());
        case AsyncLoading():
          break;
      }
    });

    final user = _useCases.getCurrentUser();

    if (user == null) {
      return const AuthUnauthenticated();
    }

    return AuthAuthenticated(user);
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await _useCases.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    switch (result) {
      case Success(:final data):
        state = AuthAuthenticated(data);
      case Failure(:final exception):
        state = AuthFailure(exception.message);
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await _useCases.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );

    switch (result) {
      case Success(:final data):
        state = AuthAuthenticated(data);
      case Failure(:final exception):
        state = AuthFailure(exception.message);
    }
  }

  Future<void> resetPasswordForEmail({required String email}) async {
    state = const AuthLoading();

    final result = await _useCases.resetPasswordForEmail(email: email);

    switch (result) {
      case Success():
        state = AuthPasswordRecoverySent(email);
      case Failure(:final exception):
        state = AuthFailure(exception.message);
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();

    final result = await _useCases.signOut();

    switch (result) {
      case Success():
        state = const AuthUnauthenticated();
      case Failure(:final exception):
        state = AuthFailure(exception.message);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();

    final result = await _useCases.signInWithGoogle();

    switch (result) {
      case Success():
        break;
      case Failure(:final exception):
        state = AuthFailure(exception.message);
    }
  }
}
