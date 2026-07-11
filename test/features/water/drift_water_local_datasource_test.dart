import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/database.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/services/logger_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/water/data/datasources/drift_water_local_datasource.dart';
import 'package:helpbari/features/water/data/datasources/local_water_datasource.dart';
import 'package:helpbari/features/water/data/dtos/water_record_dto.dart';
import 'package:helpbari/features/water/data/repositories/drift_primary_water_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('creates, updates and soft deletes offline in Drift', () async {
    final datasource = _datasource(database, 'user-a');
    await datasource.save(_dto(id: 'one', amount: 200));
    await datasource.save(_dto(id: 'one', amount: 500));

    expect((await datasource.getHistory()).single.amountInMl, 500);
    expect(
      (await datasource.pendingSync()).single.syncMetadata.syncStatus,
      SyncStatus.pendingCreate,
    );

    await datasource.delete('one');
    expect(await datasource.getHistory(), isEmpty);
    final tombstone = await datasource.pendingById('one');
    expect(tombstone?.syncMetadata.syncStatus, SyncStatus.pendingDelete);
    expect(tombstone?.syncMetadata.deletedAt, isNotNull);
  });

  test('marks failed with original status and then synced', () async {
    final datasource = _datasource(database, 'user-a');
    await datasource.save(_dto(id: 'retry'));
    await datasource.markFailed('retry', 'network');

    expect(
      (await datasource.pendingSync()).single.syncMetadata.syncStatus,
      SyncStatus.pendingCreate,
    );
    await datasource.markSynced('retry');
    expect(await datasource.pendingSync(), isEmpty);
  });

  test('isolates same id, cursor and anonymous sync', () async {
    final first = _datasource(database, 'user-a');
    final second = _datasource(database, 'user-b');
    final anonymous = _datasource(database, 'anonymous');
    await first.save(_dto(id: 'same', amount: 200));
    await second.save(_dto(id: 'same', amount: 400));
    await anonymous.save(_dto(id: 'anonymous', amount: 600));
    final cursor = DateTime.utc(2026, 7, 10);
    await first.saveCursor('water', cursor);

    expect((await first.getHistory()).single.amountInMl, 200);
    expect((await second.getHistory()).single.amountInMl, 400);
    expect(await first.getLastPullAt('water'), cursor.toLocal());
    expect(await second.getLastPullAt('water'), isNull);
    expect(await anonymous.pendingSync(), isEmpty);
  });

  test('read fallback does not change SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = SharedPreferencesLocalStorageService(preferences);
    final legacyDatabase = SharedPreferencesLocalDatabase(storage);
    final legacy = LocalWaterDatasource(
      database: legacyDatabase,
      clock: const _Clock(),
      userId: 'user-a',
    );
    await legacy.save(_dto(id: 'legacy', amount: 300));
    final before = preferences.getString(
      'local_database.collection.water_records',
    );
    final repository = DriftPrimaryWaterRepository(
      driftDatasource: () async => throw StateError('unavailable'),
      fallbackDatasource: legacy,
      logger: _Logger(),
    );

    final history = await repository.getHistory();

    expect(history.single.id, 'legacy');
    expect(
      preferences.getString('local_database.collection.water_records'),
      before,
    );
  });

  test('does not use legacy fallback after cutover', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = SharedPreferencesLocalStorageService(preferences);
    final legacy = LocalWaterDatasource(
      database: SharedPreferencesLocalDatabase(storage),
      clock: const _Clock(),
      userId: 'user-a',
    );
    await legacy.save(_dto(id: 'stale-legacy'));
    final repository = DriftPrimaryWaterRepository(
      driftDatasource: () async => throw StateError('unavailable'),
      fallbackDatasource: legacy,
      logger: _Logger(),
      hasCutoverMirror: () => true,
    );

    await expectLater(
      repository.getHistory(),
      throwsA(isA<WaterDriftUnavailableAfterCutoverException>()),
    );
  });

  test('reads exclusively from Drift after cutover', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = SharedPreferencesLocalStorageService(preferences);
    final drift = _datasource(database, 'user-a');
    await drift.save(_dto(id: 'drift-only', amount: 700));
    final legacy = LocalWaterDatasource(
      database: SharedPreferencesLocalDatabase(storage),
      clock: const _Clock(),
      userId: 'user-a',
    );
    await legacy.save(_dto(id: 'legacy-only', amount: 100));
    final repository = DriftPrimaryWaterRepository(
      driftDatasource: () async => drift,
      fallbackDatasource: legacy,
      logger: _Logger(),
      ensureCutover: () async {},
      hasCutoverMirror: () => true,
    );

    final history = await repository.getHistory();

    expect(history.map((record) => record.id), ['drift-only']);
  });
}

DriftWaterLocalDatasource _datasource(AppDatabase database, String userId) =>
    DriftWaterLocalDatasource(
      dao: database.waterDao,
      clock: const _Clock(),
      userId: userId,
    );

WaterRecordDto _dto({required String id, int amount = 250}) {
  final now = DateTime.utc(2026, 7, 9, 12);
  return WaterRecordDto(
    id: id,
    amountInMl: amount,
    recordedAt: now,
    syncMetadata: SyncMetadata(
      id: id,
      userId: 'ignored-by-local-datasource',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    ),
  );
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 9, 12);
}

class _Logger implements LoggerService {
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void info(String message) {}
  @override
  void warning(String message) {}
}
