import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/result/result.dart';
import 'package:helpbari/features/auth/data/repositories/dev_auth_repository.dart';

void main() {
  group('DevAuthRepository', () {
    test('signs in with email and keeps current session', () async {
      final repository = DevAuthRepository();
      addTearDown(repository.dispose);

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@helpbari.test',
        password: 'password123',
      );

      expect(result, isA<Success>());
      expect(repository.currentUser?.email, 'user@helpbari.test');
      expect(repository.hasSession, isTrue);
    });

    test('signs out and emits unauthenticated session', () async {
      final repository = DevAuthRepository();
      addTearDown(repository.dispose);

      await repository.signInWithEmailAndPassword(
        email: 'user@helpbari.test',
        password: 'password123',
      );

      final emittedUsers = <Object?>[];
      final subscription = repository.authStateChanges.listen(emittedUsers.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      await repository.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(emittedUsers.first, isNotNull);
      expect(emittedUsers.last, isNull);
      expect(repository.currentUser, isNull);
      expect(repository.hasSession, isFalse);
    });

    test('reset password succeeds without changing current session', () async {
      final repository = DevAuthRepository();
      addTearDown(repository.dispose);
      final previousUser = repository.currentUser;

      final result = await repository.resetPasswordForEmail(
        email: 'user@helpbari.test',
      );

      expect(result, isA<Success<void>>());
      expect(repository.currentUser, same(previousUser));
      expect(repository.hasSession, isTrue);
    });
  });
}
