import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

class AuthViewModel extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    final user = _repository.currentUser;

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

    final result = await _repository.signInWithEmailAndPassword(
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

    final result = await _repository.signUpWithEmailAndPassword(
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

  Future<void> signOut() async {
    state = const AuthLoading();

    final result = await _repository.signOut();

    switch (result) {
      case Success():
        state = const AuthUnauthenticated();
      case Failure(:final exception):
        state = AuthFailure(exception.message);
    }
  }
}
