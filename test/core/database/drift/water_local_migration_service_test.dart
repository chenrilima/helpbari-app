import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/migrations/water_local_migration_service.dart';
import 'package:helpbari/core/database/local_database_record.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/sync/sync_metadata.dart';
import 'package:helpbari/core/sync/sync_status.dart';

void main() {
  late AppDatabase database;
  late _MemoryStorage storage;
  late WaterLocalMigrationService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    storage = _MemoryStorage();
    service = WaterLocalMigrationService(database: database, storage: storage);
  });

  tearDown(() => database.close());

  test('migrates a valid legacy water record', () async {
    storage.writeRecords([_record(id: 'water-1', userId: 'user-a')]);
    final legacyBefore = storage.getString(
      WaterLocalMigrationService.legacyStorageKey,
    );

    final report = await service.migrate();
    final migrated = await database.waterDao.getByUserAndId(
      'user-a',
      'water-1',
    );

    expect(report.toJson(), containsPair('read', 1));
    expect(report.imported, 1);
    expect(report.invalid, 0);
    expect(migrated?.amountMl, 250);
    expect(
      storage.getString(WaterLocalMigrationService.legacyStorageKey),
      legacyBefore,
    );
  });

  test('re-execution is idempotent and does not duplicate records', () async {
    storage.writeRecords([_record(id: 'water-1', userId: 'user-a')]);

    final first = await service.migrate();
    final second = await service.migrate();
    final rows = await database.waterDao.getActiveByUser('user-a');

    expect(first.imported, 1);
    expect(second.imported, 0);
    expect(second.updated, 0);
    expect(second.ignored, 1);
    expect(second.checksum, first.checksum);
    expect(rows, hasLength(1));
  });

  test(
    'rolls back records and migration marker when an insert fails',
    () async {
      await database.customStatement('''
      CREATE TRIGGER reject_water BEFORE INSERT ON water_records
      WHEN NEW.id = 'z-boom'
      BEGIN
        SELECT RAISE(ABORT, 'forced failure');
      END
    ''');
      storage.writeRecords([
        _record(id: 'a-good', userId: 'user-a'),
        _record(id: 'z-boom', userId: 'user-a'),
      ]);

      await expectLater(service.migrate(), throwsA(anything));

      expect(await database.waterDao.getActiveByUser('user-a'), isEmpty);
      expect(await database.select(database.localMigrations).get(), isEmpty);
    },
  );

  test('keeps the greatest updatedAt during conflicts', () async {
    final old = DateTime.utc(2026, 1, 1);
    final middle = DateTime.utc(2026, 2, 1);
    final newest = DateTime.utc(2026, 3, 1);
    storage.writeRecords([
      _record(
        id: 'water-1',
        userId: 'user-a',
        updatedAt: middle,
        amountMl: 300,
      ),
    ]);
    await database.waterDao.upsert(
      WaterRecordsCompanion.insert(
        id: 'water-1',
        userId: 'user-a',
        amountMl: 500,
        recordedAt: newest,
        createdAt: old,
        updatedAt: newest,
        syncStatus: 'synced',
      ),
    );

    final ignored = await service.migrate();
    expect(ignored.ignored, 1);
    expect(
      (await database.waterDao.getByUserAndId('user-a', 'water-1'))?.amountMl,
      500,
    );

    storage.writeRecords([
      _record(
        id: 'water-1',
        userId: 'user-a',
        updatedAt: newest.add(const Duration(days: 1)),
        amountMl: 700,
      ),
    ]);
    final updated = await service.migrate();

    expect(updated.updated, 1);
    expect(
      (await database.waterDao.getByUserAndId('user-a', 'water-1'))?.amountMl,
      700,
    );
  });

  test('preserves tombstone and sync status', () async {
    final deletedAt = DateTime.utc(2026, 4, 1);
    storage.writeRecords([
      _record(
        id: 'deleted',
        userId: 'user-a',
        deletedAt: deletedAt,
        syncStatus: SyncStatus.pendingDelete,
      ),
    ]);

    await service.migrate();
    final migrated = await database.waterDao.getByUserAndId(
      'user-a',
      'deleted',
    );

    expect(migrated?.deletedAt?.toUtc(), deletedAt);
    expect(migrated?.syncStatus, SyncStatus.pendingDelete.name);
    expect(await database.waterDao.getActiveByUser('user-a'), isEmpty);
  });

  test('allows the same id for two different users', () async {
    storage.writeRecords([
      _record(id: 'same-id', userId: 'user-a', amountMl: 200),
      _record(id: 'same-id', userId: 'user-b', amountMl: 400),
    ]);

    final report = await service.migrate();

    expect(report.imported, 2);
    expect(
      (await database.waterDao.getByUserAndId('user-a', 'same-id'))?.amountMl,
      200,
    );
    expect(
      (await database.waterDao.getByUserAndId('user-b', 'same-id'))?.amountMl,
      400,
    );
  });

  test(
    'places missing userId in anonymous and excludes it from sync',
    () async {
      storage.writeRecords([_record(id: 'anonymous-water')]);

      final report = await service.migrate();
      final migrated = await database.waterDao.getByUserAndId(
        WaterLocalMigrationService.anonymousUserId,
        'anonymous-water',
      );

      expect(report.anonymous, 1);
      expect(migrated, isNotNull);
      expect(
        await database.waterDao.getPendingForSync(
          WaterLocalMigrationService.anonymousUserId,
        ),
        isEmpty,
      );
    },
  );

  test('writes marker with normalized checksum and valid count', () async {
    final firstRecord = _record(id: 'one', userId: 'user-a');
    final secondRecord = _record(id: 'two', userId: 'user-b');
    storage.writeRaw([
      firstRecord.toJson(),
      'invalid-item',
      secondRecord.toJson(),
    ]);

    final first = await service.migrate();
    final marker = await database.select(database.localMigrations).getSingle();

    expect(first.read, 3);
    expect(first.valid, 2);
    expect(first.invalid, 1);
    expect(marker.migrationKey, WaterLocalMigrationService.migrationKey);
    expect(marker.importedCount, 2);
    expect(marker.sourceChecksum, first.checksum);
    expect(first.checksum, hasLength(64));

    storage.writeRecords([secondRecord, firstRecord]);
    final reordered = await service.migrate();
    expect(reordered.checksum, first.checksum);
  });
}

LocalDatabaseRecord _record({
  required String id,
  String? userId,
  int amountMl = 250,
  DateTime? updatedAt,
  DateTime? deletedAt,
  SyncStatus syncStatus = SyncStatus.pendingCreate,
}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  final effectiveUpdatedAt = updatedAt ?? DateTime.utc(2026, 1, 2);
  return LocalDatabaseRecord(
    metadata: SyncMetadata(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: effectiveUpdatedAt,
      deletedAt: deletedAt,
      syncStatus: syncStatus,
    ),
    data: {
      'amountInMl': amountMl,
      'recordedAt': effectiveUpdatedAt.toIso8601String(),
    },
  );
}

class _MemoryStorage implements LocalStorageService {
  final Map<String, Object> _values = {};

  void writeRecords(List<LocalDatabaseRecord> records) {
    writeRaw(records.map((record) => record.toJson()).toList());
  }

  void writeRaw(List<Object> records) {
    _values[WaterLocalMigrationService.legacyStorageKey] = jsonEncode(records);
  }

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<void> setBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
