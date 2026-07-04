import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/errors/app_exception.dart';
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
        return const Failure(
          AppException(message: 'Não foi possível criar sua conta.'),
        );
      }

      return Success(AuthUser(id: user.id, email: user.email));
    } on AuthException catch (error, stackTrace) {
      return Failure(
        AppException(
          message: error.message,
          code: error.statusCode,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Failure(
        AppException(
          message: 'Erro inesperado ao criar conta.',
          stackTrace: stackTrace,
        ),
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
        return const Failure(
          AppException(message: 'Não foi possível autenticar o usuário.'),
        );
      }

      return Success(AuthUser(id: user.id, email: user.email));
    } on AuthException catch (error, stackTrace) {
      return Failure(
        AppException(
          message: error.message,
          code: error.statusCode,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Failure(
        AppException(
          message: 'Erro inesperado ao entrar.',
          stackTrace: stackTrace,
        ),
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
        AppException(
          message: 'Erro inesperado ao sair.',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
