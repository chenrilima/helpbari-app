import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/consistency/water_local_consistency_checker.dart';
import 'package:helpbari/core/database/drift/cutover/water_cutover_service.dart';
import 'package:helpbari/core/database/drift/migrations/water_local_migration_service.dart';
import 'package:helpbari/core/database/local_database_record.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/sync/sync_metadata.dart';
import 'package:helpbari/core/sync/sync_status.dart';

void main() {
  late AppDatabase database;
  late _Storage storage;
  late WaterCutoverService cutover;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    storage = _Storage();
    cutover = WaterCutoverService(database: database, storage: storage);
  });
  tearDown(() => database.close());

  test('completes cutover with versioned marker and is idempotent', () async {
    storage.records = [_record('one', 'user-a')];
    await _migrate(database, storage);

    final first = await cutover.attempt('user-a');
    final second = await cutover.attempt('user-a');
    final marker = await database.select(database.waterCutovers).getSingle();

    expect(first.completed, isTrue);
    expect(second.alreadyCompleted, isTrue);
    expect(marker.migrationKey, WaterCutoverService.migrationKey);
    expect(marker.version, WaterCutoverService.version);
    expect(marker.userId, 'user-a');
    expect(marker.recordCount, 1);
    expect(marker.databaseSchemaVersion, database.schemaVersion);
    expect(marker.checksum, hasLength(64));
    expect(cutover.isCompletedMirror('user-a'), isTrue);
  });

  test('blocks cutover when the databases diverge', () async {
    storage.records = [_record('one', 'user-a')];
    await _migrate(database, storage);
    final row = await database.waterDao.getByUserAndId('user-a', 'one');
    await database.waterDao.upsert(
      WaterRecordsCompanion(
        id: Value(row!.id),
        userId: Value(row.userId),
        amountMl: const Value(999),
        recordedAt: Value(row.recordedAt),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        syncStatus: Value(row.syncStatus),
      ),
    );

    final result = await cutover.attempt('user-a');

    expect(result.completed, isFalse);
    expect(result.blockedReason, 'not_converged');
    expect(await database.select(database.waterCutovers).get(), isEmpty);
  });

  test('anonymous never completes cutover', () async {
    storage.records = [_record('one', null)];
    await _migrate(database, storage);
    final result = await cutover.attempt('anonymous');
    expect(result.completed, isFalse);
    expect(result.blockedReason, 'anonymous');
  });

  test(
    'new Drift writes do not create legacy divergence after cutover',
    () async {
      storage.records = [_record('one', 'user-a')];
      await _migrate(database, storage);
      await cutover.attempt('user-a');
      final now = DateTime.utc(2026, 8, 1);
      await database.waterDao.upsert(
        WaterRecordsCompanion.insert(
          id: 'new-drift',
          userId: 'user-a',
          amountMl: 300,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate.name,
        ),
      );

      final report = await WaterLocalConsistencyChecker(
        database: database,
        storage: storage,
      ).check();

      expect(report.usersAnalyzed, isEmpty);
      expect(report.consistent, isTrue);
    },
  );

  test('cutover markers are isolated by user', () async {
    storage.records = [_record('same', 'user-a'), _record('same', 'user-b')];
    await _migrate(database, storage);
    await cutover.attempt('user-a');

    expect(await cutover.isCompleted('user-a'), isTrue);
    expect(await cutover.isCompleted('user-b'), isFalse);
    final report = await WaterLocalConsistencyChecker(
      database: database,
      storage: storage,
    ).check();
    expect(report.usersAnalyzed, ['user-b']);
  });
}

Future<void> _migrate(AppDatabase db, LocalStorageService storage) =>
    WaterLocalMigrationService(database: db, storage: storage).migrate();

LocalDatabaseRecord _record(String id, String? userId) {
  final now = DateTime.utc(2026, 7, 1);
  return LocalDatabaseRecord(
    metadata: SyncMetadata(
      id: id,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    ),
    data: {'amountInMl': 200, 'recordedAt': now.toIso8601String()},
  );
}

class _Storage implements LocalStorageService {
  final Map<String, Object> values = {};
  set records(List<LocalDatabaseRecord> records) =>
      values[WaterLocalMigrationService.legacyStorageKey] = jsonEncode(
        records.map((record) => record.toJson()).toList(),
      );
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  String? getString(String key) => values[key] as String?;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
