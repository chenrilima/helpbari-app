import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/migrations/profile_legacy_service.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/profile/data/datasources/drift_profile_local_datasource.dart';
import 'package:helpbari/features/profile/data/datasources/profile_supabase_datasource.dart';
import 'package:helpbari/features/profile/data/dtos/profile_dto.dart';
import 'package:helpbari/features/profile/data/repositories/profile_sync_repository.dart';
import 'package:helpbari/features/profile/domain/entities/entities.dart';
import 'package:helpbari/features/profile/domain/value_objects/value_objects.dart';

void main() {
  late AppDatabase database;
  late _Storage storage;
  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    storage = _Storage();
  });
  tearDown(() => database.close());

  test('local schema v9 contains photo_storage_path', () async {
    expect(database.schemaVersion, 9);
    final columns = await database
        .customSelect('PRAGMA table_info(profile_records)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      contains('photo_storage_path'),
    );
  });

  test('CRUD, soft delete and pending status are isolated by userId', () async {
    final first = _local(database, 'user-a');
    final second = _local(database, 'user-b');
    await first.save(_profile('user-a', 'Ana'));
    await second.save(_profile('user-b', 'Bia'));
    expect((await first.getProfile())?.name, 'Ana');
    expect((await second.getProfile())?.name, 'Bia');

    await first.save(_profile('user-a', 'Ana Maria'));
    expect(
      (await first.pending()).single.syncMetadata.syncStatus,
      SyncStatus.pendingCreate,
    );
    await first.softDelete('user-a');
    expect(await first.getProfile(), isNull);
    expect((await first.pending()).single.syncMetadata.deletedAt, isNotNull);
    expect((await second.getProfile())?.name, 'Bia');
  });

  test(
    'push marks synced only after remote success and cursor is per user',
    () async {
      final local = _local(database, 'user-a');
      await local.save(_profile('user-a', 'Ana'));
      final remote = _Remote();
      final repository = ProfileSyncRepository(
        local: () async => local,
        remote: remote,
        userId: 'user-a',
      );
      final operation = (await repository.pendingOperations()).single;
      await repository.push(operation);
      expect(await local.pending(), hasLength(1));
      await repository.markSynced(operation.recordId, syncedAt: DateTime.now());
      expect(await local.pending(), isEmpty);
      await repository.saveSuccessfulSync(DateTime.utc(2026, 7, 11));
      expect(
        (await repository.getLastPullAt())?.toUtc(),
        DateTime.utc(2026, 7, 11),
      );
      expect(await _local(database, 'user-b').getLastPullAt(), isNull);
    },
  );

  test('remote pull updates Drift and rejects another user', () async {
    final local = _local(database, 'user-a');
    await local.save(_profile('user-a', 'Old'));
    await local.markSynced('user-a');
    final remote = _dto('user-a', 'Remote', DateTime.utc(2028));
    expect(await local.applyRemoteAndMarkSynced(remote), isTrue);
    expect((await local.getProfile())?.name, 'Remote');
    expect(
      await local.applyRemote(_dto('user-b', 'Leak', DateTime.utc(2029))),
      isFalse,
    );
    expect((await local.getProfile())?.name, 'Remote');
  });

  test(
    'photo storage path round-trips through Drift and sync payload',
    () async {
      final local = _local(database, 'user-a');
      final profile = _profile(
        'user-a',
        'Ana',
      ).copyWith(photoStoragePath: 'user-a/profile/photo.jpg');
      await local.save(profile);
      expect(
        (await local.getProfile())?.photoStoragePath,
        'user-a/profile/photo.jpg',
      );
      final repository = ProfileSyncRepository(
        local: () async => local,
        remote: _Remote(),
        userId: 'user-a',
      );
      final operation = (await repository.pendingOperations()).single;
      expect(
        operation.payload['photo_storage_path'],
        'user-a/profile/photo.jpg',
      );
    },
  );

  test(
    'migration preserves SharedPreferences and creates cutover marker',
    () async {
      final dto = _dto('user-a', 'Legacy', DateTime.utc(2026));
      storage.values[ProfileLegacyService.legacyKey] = jsonEncode([
        dto.toRecord().toJson(),
      ]);
      final before = storage.getString(ProfileLegacyService.legacyKey);
      final service = ProfileLegacyService(
        database: database,
        storage: storage,
      );
      final report = await service.migrate();
      final cutover = await service.ensureUserAndAttemptCutover('user-a');
      expect(report.imported, 1);
      expect(cutover.completed, isTrue);
      expect(storage.getString(ProfileLegacyService.legacyKey), before);
      expect((await database.profileDao.getByUser('user-a'))?.name, 'Legacy');
    },
  );
}

DriftProfileLocalDatasource _local(AppDatabase db, String userId) =>
    DriftProfileLocalDatasource(
      dao: db.profileDao,
      clock: const _Clock(),
      userId: userId,
    );

Profile _profile(String id, String name) => Profile(
  id: id,
  name: name,
  email: '$id@example.com',
  createdAt: AppDate(DateTime.utc(2025), clock: const _Clock()),
  birthDate: AppDate(DateTime.utc(1990), clock: const _Clock()),
  height: Height.create(170)!,
  initialWeight: Weight.create(100)!,
  targetWeight: Weight.create(70)!,
  surgeryDate: AppDate(DateTime.utc(2024), clock: const _Clock()),
  surgeryType: SurgeryType.sleeve,
  clock: const _Clock(),
);

ProfileDto _dto(String userId, String name, DateTime updatedAt) =>
    ProfileDto.fromEntity(
      _profile(userId, name),
      now: updatedAt,
      userId: userId,
    );

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 11);
}

class _Storage implements LocalStorageService {
  final values = <String, Object>{};
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  String? getString(String key) => values[key] as String?;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

class _Remote implements ProfileRemoteDatasource {
  @override
  Future<List<ProfileDto>> pull(String userId, DateTime? updatedAfter) async =>
      [];
  @override
  Future<ProfileDto> upsert(ProfileDto value, String userId) async => _dto(
    userId,
    value.name,
    value.syncMetadata.updatedAt.add(const Duration(seconds: 1)),
  );
}
