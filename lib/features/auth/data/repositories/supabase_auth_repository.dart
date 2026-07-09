import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/config/environment.dart';
import '../../../../core/failures/failures.dart' as domain_failures;
import '../../../../core/result/result.dart';
import '../../../../core/supabase/supabase_error_mapper.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../mappers/auth_user_mapper.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._datasource);

  final AuthDatasource _datasource;

  @override
  AuthUser? get currentUser => _datasource.currentUser?.toDomain();

  @override
  bool get hasSession => _datasource.currentSession != null;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _datasource.authStateChanges.map((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        return currentUser;
      }

      return event.session?.user.toDomain();
    });
  }

  @override
  Stream<bool> get passwordRecoveryChanges {
    return _datasource.authStateChanges
        .where((event) => event.event == AuthChangeEvent.passwordRecovery)
        .map((event) => event.session != null);
  }

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _datasource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      return _authUserResult(
        response.user,
        emptyUserMessage: 'Não foi possível criar sua conta.',
      );
    } catch (error, stackTrace) {
      return Failure(SupabaseErrorMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _datasource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return _authUserResult(
        response.user,
        emptyUserMessage: 'Não foi possível autenticar o usuário.',
      );
    } catch (error, stackTrace) {
      return Failure(SupabaseErrorMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> resetPasswordForEmail({required String email}) async {
    try {
      await _datasource.resetPasswordForEmail(
        email: email,
        redirectTo: Environment.appRedirectUrl,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(SupabaseErrorMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<AuthUser>> updatePassword({required String password}) async {
    if (_datasource.currentSession == null) {
      return Failure(
        const domain_failures.AuthFailure(
          message:
              'Link de recuperação inválido ou expirado. Solicite um novo e-mail.',
          code: 'password_recovery_session_missing',
        ).toException(),
      );
    }

    try {
      final response = await _datasource.updatePassword(password: password);

      return _authUserResult(
        response.user,
        emptyUserMessage: 'Não foi possível atualizar sua senha.',
      );
    } catch (error, stackTrace) {
      return Failure(
        SupabaseErrorMapper.map(
          error,
          stackTrace,
          fallbackMessage:
              'Não foi possível atualizar sua senha. Solicite um novo link.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    try {
      await _datasource.signInWithGoogle(
        redirectTo: Environment.appRedirectUrl,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(SupabaseErrorMapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(SupabaseErrorMapper.map(error, stackTrace));
    }
  }

  Result<AuthUser> _authUserResult(
    User? user, {
    required String emptyUserMessage,
  }) {
    if (user == null) {
      return Failure(
        domain_failures.AuthFailure(
          message: emptyUserMessage,
          code: 'auth_empty_user',
        ).toException(),
      );
    }

    return Success(user.toDomain());
  }
}
