import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  bool get hasSession;

  Stream<AuthUser?> get authStateChanges;

  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Result<void>> resetPasswordForEmail({required String email});

  Future<Result<void>> signInWithGoogle();

  Future<Result<void>> signOut();
}
