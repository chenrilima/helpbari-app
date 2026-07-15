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
      if (state is AuthLoading || state is AuthPasswordRecoveryReady) return;

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
    ref.listen(passwordRecoveryChangesProvider, (previous, next) {
      switch (next) {
        case AsyncData(:final value):
          if (value) {
            state = const AuthPasswordRecoveryReady();
          }
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
      email: email.trim().toLowerCase(),
      password: password,
    );

    switch (result) {
      case Success(:final data):
        state = _hasValidSession(data.id)
            ? AuthAuthenticated(data)
            : const AuthFailure(
                'Não foi possível restaurar uma sessão válida.',
              );
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
      email: email.trim().toLowerCase(),
      password: password,
    );

    switch (result) {
      case Success(:final data):
        state = _hasValidSession(data.id)
            ? AuthAuthenticated(data)
            : const AuthEmailConfirmationRequired();
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

  Future<void> updatePassword({required String password}) async {
    state = const AuthLoading();

    final result = await _useCases.updatePassword(password: password);

    switch (result) {
      case Success(:final data):
        state = AuthPasswordUpdated(data);
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

  bool _hasValidSession(String userId) {
    final repository = ref.read(authRepositoryProvider);
    return repository.hasSession && repository.currentUser?.id == userId;
  }
}
