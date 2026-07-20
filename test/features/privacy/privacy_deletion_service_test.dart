import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/features/privacy/application/privacy_deletion_service.dart';
import 'package:helpbari/features/privacy/data/services/privacy_local_cleanup_service.dart';
import 'package:helpbari/features/privacy/domain/entities/entities.dart';
import 'package:helpbari/features/privacy/domain/repositories/repositories.dart';
import 'package:helpbari/features/privacy/domain/usecases/use_cases.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('remote deletion completes before local cleanup and logout', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _PrivacyRepository();
    var loggedOut = false;
    final service = PrivacyDeletionService(
      privacy: PrivacyUseCases(repository),
      localCleanup: PrivacyLocalCleanupService(
        database: database,
        preferences: await SharedPreferences.getInstance(),
      ),
      logout: () async => loggedOut = true,
      userId: 'user-a',
    );

    final result = await service.deleteAccount(password: 'secret');

    expect(result.completed, isTrue);
    expect(repository.accountDeleted, isTrue);
    expect(repository.storageCleared, isTrue);
    expect(repository.password, 'secret');
    expect(loggedOut, isTrue);
  });

  test('offline remote failure preserves local data and session', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _PrivacyRepository()..failRemote = true;
    var loggedOut = false;
    final service = PrivacyDeletionService(
      privacy: PrivacyUseCases(repository),
      localCleanup: PrivacyLocalCleanupService(
        database: database,
        preferences: await SharedPreferences.getInstance(),
      ),
      logout: () async => loggedOut = true,
      userId: 'user-a',
    );

    await expectLater(service.deleteData(), throwsStateError);
    expect(loggedOut, isFalse);
  });

  test('anonymous user cannot execute deletion', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _PrivacyRepository();
    final service = PrivacyDeletionService(
      privacy: PrivacyUseCases(repository),
      localCleanup: PrivacyLocalCleanupService(
        database: database,
        preferences: await SharedPreferences.getInstance(),
      ),
      logout: () async {},
      userId: 'anonymous',
    );

    await expectLater(service.deleteData(), throwsStateError);
    expect(repository.storageCleared, isFalse);
  });

  test('storage failure does not run database deletion or logout', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _PrivacyRepository()..failRemote = true;
    var loggedOut = false;
    final service = PrivacyDeletionService(
      privacy: PrivacyUseCases(repository),
      localCleanup: PrivacyLocalCleanupService(
        database: database,
        preferences: await SharedPreferences.getInstance(),
      ),
      logout: () async => loggedOut = true,
      userId: 'user-a',
    );

    await expectLater(service.deleteData(), throwsStateError);
    expect(loggedOut, isFalse);
  });

  test('repeating data deletion remains idempotent', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _PrivacyRepository();
    var logoutCount = 0;
    final service = PrivacyDeletionService(
      privacy: PrivacyUseCases(repository),
      localCleanup: PrivacyLocalCleanupService(
        database: database,
        preferences: await SharedPreferences.getInstance(),
      ),
      logout: () async => logoutCount++,
      userId: 'user-a',
    );

    await service.deleteData();
    await service.deleteData();

    expect(logoutCount, 2);
    expect(repository.storageCleared, isTrue);
  });

  test(
    'local failure after remote completion is reported as partial',
    () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = _PrivacyRepository();
      var loggedOut = false;
      final service = PrivacyDeletionService(
        privacy: PrivacyUseCases(repository),
        localCleanup: PrivacyLocalCleanupService(
          database: database,
          preferences: await SharedPreferences.getInstance(),
        ),
        logout: () async => loggedOut = true,
        userId: '',
      );

      await expectLater(
        service.deleteData(),
        throwsA(isA<PrivacyPartialDeletionException>()),
      );
      expect(loggedOut, isFalse);
    },
  );
}

class _PrivacyRepository implements PrivacyRepository {
  bool accountDeleted = false;
  bool storageCleared = false;
  bool failRemote = false;
  String? password;
  @override
  bool get passwordRequired => true;
  @override
  Future<PrivacyConsent> acceptCurrentDocuments() => throw UnimplementedError();
  @override
  Future<void> deleteRemoteAccount({String? password}) async {
    if (failRemote) throw StateError('offline');
    accountDeleted = true;
    storageCleared = true;
    this.password = password;
  }

  @override
  Future<void> deleteRemoteData({String? password}) async {
    if (failRemote) throw StateError('offline');
    storageCleared = true;
  }

  @override
  Future<List<PrivacyConsent>> getConsentHistory() async => [];
  @override
  Future<bool> hasCurrentConsent() async => false;
  @override
  Future<void> requestDefinitiveRemoval() async {}
}
