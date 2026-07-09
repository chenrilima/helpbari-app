import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

abstract interface class AuthDatasource {
  User? get currentUser;

  Session? get currentSession;

  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> resetPasswordForEmail({
    required String email,
    required String redirectTo,
  });

  Future<bool> signInWithGoogle({required String redirectTo});

  Future<void> signOut();
}
