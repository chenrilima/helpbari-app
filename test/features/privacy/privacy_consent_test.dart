import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/services.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/privacy/data/datasources/drift_privacy_consent_datasource.dart';
import 'package:helpbari/features/privacy/data/datasources/privacy_supabase_datasource.dart';
import 'package:helpbari/features/privacy/data/dtos/privacy_consent_dto.dart';
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

  test(
    'remote consent replaces a local id for the same document version',
    () async {
      final repository = _repository(database, 'user-a');
      await repository.acceptCurrentDocuments();
      final local = DriftPrivacyConsentDatasource(
        dao: database.privacyConsentDao,
        userId: 'user-a',
      );
      final remoteTime = DateTime.utc(2026, 7, 16, 13);

      final applied = await local.applyRemote(
        PrivacyConsentDto(
          consent: PrivacyConsent(
            id: 'remote-consent',
            userId: 'user-a',
            termsVersion: PrivacyDocuments.termsVersion,
            privacyVersion: PrivacyDocuments.privacyVersion,
            acceptedAt: remoteTime,
            deviceId: 'remote-device',
            timezone: 'America/Sao_Paulo',
          ),
          syncMetadata: SyncMetadata(
            id: 'remote-consent',
            userId: 'user-a',
            createdAt: remoteTime,
            updatedAt: remoteTime,
            syncStatus: SyncStatus.synced,
          ),
        ),
      );

      final history = await repository.getConsentHistory();
      expect(applied, isTrue);
      expect(history, hasLength(1));
      expect(history.single.id, 'remote-consent');
    },
  );

  test('anonymous cannot register legal acceptance', () async {
    await expectLater(
      _repository(database, 'anonymous').acceptCurrentDocuments(),
      throwsStateError,
    );
  });

  test('anonymous cannot request definitive removal', () async {
    await expectLater(
      _repository(database, 'anonymous').requestDefinitiveRemoval(),
      throwsStateError,
    );
  });

  test('authenticated user can request definitive removal', () async {
    final remote = _Remote();

    await _repository(
      database,
      'user-a',
      remote: remote,
    ).requestDefinitiveRemoval();

    expect(remote.requested, isTrue);
  });
}

DriftPrivacyRepository _repository(
  AppDatabase database,
  String userId, {
  PrivacyRemoteDatasource? remote,
}) => DriftPrivacyRepository(
  local: () async => DriftPrivacyConsentDatasource(
    dao: database.privacyConsentDao,
    userId: userId,
  ),
  remote: remote,
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

class _Remote implements PrivacyRemoteDatasource {
  bool requested = false;

  @override
  bool get passwordRequired => false;

  @override
  Future<void> deleteAccount({String? password}) async {}

  @override
  Future<void> deleteData({String? password}) async {}

  @override
  Future<List<PrivacyConsentDto>> pull(
    String userId,
    DateTime? updatedAfter,
  ) async => const [];

  @override
  Future<void> requestDefinitiveRemoval() async => requested = true;

  @override
  Future<PrivacyConsentDto> upsert(PrivacyConsentDto value) async => value;
}
