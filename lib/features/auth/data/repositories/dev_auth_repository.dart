import 'dart:async';

import '../../../../core/result/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class DevAuthRepository implements AuthRepository {
  DevAuthRepository()
    : _currentUser = const AuthUser(
        id: 'dev-user',
        email: 'dev@helpbari.local',
      );

  final _controller = StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get hasSession => _currentUser != null;

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _authenticate(email);
  }

  @override
  Future<Result<AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _authenticate(email);
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    const user = AuthUser(
      id: 'dev-google-user',
      email: 'google@helpbari.local',
    );
    _currentUser = user;
    _controller.add(user);
    return const Success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _controller.add(null);
    return const Success(null);
  }

  Future<Result<AuthUser>> _authenticate(String email) async {
    final user = AuthUser(id: 'dev-user', email: email);
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  void dispose() {
    _controller.close();
  }
}
