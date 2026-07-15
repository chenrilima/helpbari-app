import '../../domain/entities/auth_user.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthEmailConfirmationRequired extends AuthState {
  const AuthEmailConfirmationRequired();
}

final class AuthPasswordRecoverySent extends AuthState {
  const AuthPasswordRecoverySent(this.email);

  final String email;
}

final class AuthPasswordRecoveryReady extends AuthState {
  const AuthPasswordRecoveryReady();
}

final class AuthPasswordUpdated extends AuthState {
  const AuthPasswordUpdated(this.user);

  final AuthUser user;
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}
