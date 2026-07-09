import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/failures/failures.dart' as domain_failures;
import '../../../../core/result/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthUser? get currentUser {
    final user = _client.auth.currentUser;

    if (user == null) return null;

    return AuthUser(id: user.id, email: user.email);
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;

      if (user == null) return null;

      return AuthUser(id: user.id, email: user.email);
    });
  }

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        return Failure(
          const domain_failures.StorageFailure(
            message: 'Não foi possível criar sua conta.',
            code: 'auth_empty_user',
          ).toException(),
        );
      }

      return Success(AuthUser(id: user.id, email: user.email));
    } on AuthException catch (error, stackTrace) {
      return Failure(
        domain_failures.StorageFailure(
          message: error.message,
          code: error.statusCode,
        ).toException(stackTrace: stackTrace),
      );
    } catch (error, stackTrace) {
      return Failure(
        const domain_failures.UnexpectedFailure(
          message: 'Erro inesperado ao criar conta.',
        ).toException(stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        return Failure(
          const domain_failures.StorageFailure(
            message: 'Não foi possível autenticar o usuário.',
            code: 'auth_empty_user',
          ).toException(),
        );
      }

      return Success(AuthUser(id: user.id, email: user.email));
    } on AuthException catch (error, stackTrace) {
      return Failure(
        domain_failures.StorageFailure(
          message: error.message,
          code: error.statusCode,
        ).toException(stackTrace: stackTrace),
      );
    } catch (error, stackTrace) {
      return Failure(
        const domain_failures.UnexpectedFailure(
          message: 'Erro inesperado ao entrar.',
        ).toException(stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        const domain_failures.UnexpectedFailure(
          message: 'Erro inesperado ao sair.',
        ).toException(stackTrace: stackTrace),
      );
    }
  }
}
