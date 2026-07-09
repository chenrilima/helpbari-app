import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCases {
  const AuthUseCases({
    required this.getCurrentUser,
    required this.watchAuthState,
    required this.signInWithEmailAndPassword,
    required this.signUpWithEmailAndPassword,
    required this.resetPasswordForEmail,
    required this.signInWithGoogle,
    required this.signOut,
  });

  final GetCurrentAuthUserUseCase getCurrentUser;
  final WatchAuthStateUseCase watchAuthState;
  final SignInWithEmailAndPasswordUseCase signInWithEmailAndPassword;
  final SignUpWithEmailAndPasswordUseCase signUpWithEmailAndPassword;
  final ResetPasswordForEmailUseCase resetPasswordForEmail;
  final SignInWithGoogleUseCase signInWithGoogle;
  final SignOutUseCase signOut;
}

class GetCurrentAuthUserUseCase {
  const GetCurrentAuthUserUseCase(this._repository);

  final AuthRepository _repository;

  AuthUser? call() => _repository.currentUser;
}

class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AuthUser?> call() => _repository.authStateChanges;
}

class SignInWithEmailAndPasswordUseCase {
  const SignInWithEmailAndPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}

class SignUpWithEmailAndPasswordUseCase {
  const SignUpWithEmailAndPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}

class ResetPasswordForEmailUseCase {
  const ResetPasswordForEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    return _repository.resetPasswordForEmail(email: email);
  }
}

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signInWithGoogle();
}

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
