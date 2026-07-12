import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/services.dart';
import 'package:helpbari/features/privacy/data/datasources/drift_privacy_consent_datasource.dart';
import 'package:helpbari/features/privacy/data/repositories/drift_privacy_repository.dart';
import 'package:helpbari/features/privacy/domain/entities/entities.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('acceptance is offline-first, idempotent and versioned', () async {
    final repository = _repository(database, 'user-a');
    final first = await repository.acceptCurrentDocuments();
    final second = await repository.acceptCurrentDocuments();
    final local = DriftPrivacyConsentDatasource(
      dao: database.privacyConsentDao,
      userId: 'user-a',
    );

    expect(second.id, first.id);
    expect(first.termsVersion, PrivacyDocuments.termsVersion);
    expect(first.privacyVersion, PrivacyDocuments.privacyVersion);
    expect(await repository.hasCurrentConsent(), isTrue);
    expect(await local.pending(), hasLength(1));
  });

  test('consent history and pending operations are isolated by user', () async {
    await _repository(database, 'user-a').acceptCurrentDocuments();
    await _repository(database, 'user-b').acceptCurrentDocuments();

    final userA = await _repository(database, 'user-a').getConsentHistory();
    final userB = await _repository(database, 'user-b').getConsentHistory();

    expect(userA, hasLength(1));
    expect(userB, hasLength(1));
    expect(userA.single.userId, 'user-a');
    expect(userB.single.userId, 'user-b');
  });

  test('anonymous cannot register legal acceptance', () async {
    await expectLater(
      _repository(database, 'anonymous').acceptCurrentDocuments(),
      throwsStateError,
    );
  });
}

DriftPrivacyRepository _repository(AppDatabase database, String userId) =>
    DriftPrivacyRepository(
      local: () async => DriftPrivacyConsentDatasource(
        dao: database.privacyConsentDao,
        userId: userId,
      ),
      remote: null,
      clock: const _Clock(),
      uuid: _Uuid(userId),
      userId: userId,
      deviceId: () async => 'device-$userId',
      timezone: () async => 'America/Sao_Paulo',
    );

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 16, 12);
}

class _Uuid implements UuidService {
  const _Uuid(this.value);
  final String value;
  @override
  String generate() => 'consent-$value';
}
