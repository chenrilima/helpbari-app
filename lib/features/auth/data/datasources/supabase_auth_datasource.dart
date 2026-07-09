import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/supabase/interceptors/supabase_request_interceptor.dart';
import 'auth_datasource.dart';

class SupabaseAuthDatasource implements AuthDatasource {
  const SupabaseAuthDatasource({
    required SupabaseClient client,
    required SupabaseInterceptorRunner interceptorRunner,
  }) : _client = client,
       _interceptorRunner = interceptorRunner;

  final SupabaseClient _client;
  final SupabaseInterceptorRunner _interceptorRunner;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _interceptorRunner.run(
      context: const SupabaseRequestContext(
        operation: 'auth.signInWithPassword',
        metadata: {'requiresAuth': false},
      ),
      request: () =>
          _client.auth.signInWithPassword(email: email, password: password),
    );
  }

  @override
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _interceptorRunner.run(
      context: const SupabaseRequestContext(
        operation: 'auth.signUp',
        metadata: {'requiresAuth': false},
      ),
      request: () => _client.auth.signUp(email: email, password: password),
    );
  }

  @override
  Future<bool> signInWithGoogle({required String redirectTo}) {
    return _interceptorRunner.run(
      context: const SupabaseRequestContext(
        operation: 'auth.signInWithOAuth.google',
        metadata: {'requiresAuth': false},
      ),
      request: () => _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      ),
    );
  }

  @override
  Future<void> signOut() {
    return _interceptorRunner.run(
      context: const SupabaseRequestContext(
        operation: 'auth.signOut',
        metadata: {'requiresAuth': true},
      ),
      request: _client.auth.signOut,
    );
  }
}
