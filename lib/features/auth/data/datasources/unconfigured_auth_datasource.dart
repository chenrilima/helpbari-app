import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/failures/failures.dart';
import 'auth_datasource.dart';

class UnconfiguredAuthDatasource implements AuthDatasource {
  const UnconfiguredAuthDatasource();

  AppException get _exception {
    return const NetworkFailure(
      message: 'Supabase não está configurado para este ambiente.',
      code: 'supabase_not_configured',
    ).toException();
  }

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw _exception;
  }

  @override
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw _exception;
  }

  @override
  Future<bool> signInWithGoogle({required String redirectTo}) {
    throw _exception;
  }

  @override
  Future<void> signOut() {
    throw _exception;
  }
}
