import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/water/data/datasources/local_water_datasource.dart';
import 'package:helpbari/features/water/data/dtos/water_record_dto.dart';
import 'package:helpbari/features/water/data/repositories/local_water_repository.dart';
import 'package:helpbari/features/water/domain/entities/entities.dart';
import 'package:helpbari/features/water/domain/value_objects/value_objects.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists water records sorted by recorded date descending', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _repository();

    await repository.create(_record(id: 'older', date: DateTime(2026, 7, 1)));
    await repository.create(_record(id: 'newer', date: DateTime(2026, 7, 9)));

    final history = await repository.getHistory();

    expect(history.map((record) => record.id), ['newer', 'older']);
    expect(history.first.amount.valueInMl, 250);
  });

  test(
    'updates amount and recorded date without duplicating the record',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = await _repository(userId: 'user-1');
      await repository.create(_record(id: 'water-1'));

      await repository.update(
        _record(id: 'water-1', amount: 500, date: DateTime(2026, 7, 8)),
      );

      final history = await repository.getHistory();
      expect(history, hasLength(1));
      expect(history.single.amount.valueInMl, 500);
      expect(history.single.recordedAt, DateTime(2026, 7, 8));
    },
  );

  test('soft delete hides record and keeps a pending tombstone', () async {
    SharedPreferences.setMockInitialValues({});
    final setup = await _setup(userId: 'user-1');
    await setup.repository.create(_record(id: 'water-1'));

    await setup.repository.delete('water-1');

    expect(await setup.repository.getHistory(), isEmpty);
    final stored = await setup.database.getById(
      LocalWaterDatasource.collection,
      'water-1',
    );
    expect(stored, isNotNull);
    expect(stored!.metadata.deletedAt, DateTime(2026, 7, 9, 12));
    expect(stored.metadata.syncStatus, SyncStatus.pendingDelete);
  });

  test('keeps local records isolated by user', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await _setup(userId: 'user-1');
    await first.repository.create(_record(id: 'user-1-water'));
    final second = LocalWaterRepository(
      LocalWaterDatasource(
        database: first.database,
        clock: const _FixedClock(),
        userId: 'user-2',
      ),
    );
    await second.create(_record(id: 'user-2-water'));

    expect((await first.repository.getHistory()).map((item) => item.id), [
      'user-1-water',
    ]);
    expect((await second.getHistory()).map((item) => item.id), [
      'user-2-water',
    ]);
  });

  test('applying the same remote id twice performs an upsert', () async {
    SharedPreferences.setMockInitialValues({});
    final setup = await _setup(userId: 'user-1');
    final datasource = LocalWaterDatasource(
      database: setup.database,
      clock: const _FixedClock(),
      userId: 'user-1',
    );
    final remote = WaterRecordDto(
      id: 'remote-1',
      amountInMl: 300,
      recordedAt: DateTime(2026, 7, 9),
      syncMetadata: SyncMetadata(
        id: 'remote-1',
        userId: 'user-1',
        createdAt: DateTime(2026, 7, 9),
        updatedAt: DateTime(2026, 7, 9, 10),
        syncStatus: SyncStatus.synced,
      ),
    );

    await datasource.applyRemote(remote);
    await datasource.applyRemote(remote);

    expect(await setup.repository.getHistory(), hasLength(1));
  });

  test(
    'failed create keeps its original operation for the next sync',
    () async {
      SharedPreferences.setMockInitialValues({});
      final setup = await _setup(userId: 'user-1');
      final datasource = LocalWaterDatasource(
        database: setup.database,
        clock: const _FixedClock(),
        userId: 'user-1',
      );
      await setup.repository.create(_record(id: 'retry-1'));

      await datasource.markFailed('retry-1');
      await datasource.markFailed('retry-1');

      final pending = await datasource.pendingSync();
      expect(pending, hasLength(1));
      expect(pending.single.syncMetadata.syncStatus, SyncStatus.pendingCreate);
    },
  );
}

Future<LocalWaterRepository> _repository({String? userId}) async {
  return (await _setup(userId: userId)).repository;
}

Future<_WaterSetup> _setup({String? userId}) async {
  final preferences = await SharedPreferences.getInstance();
  final storage = SharedPreferencesLocalStorageService(preferences);
  final database = SharedPreferencesLocalDatabase(storage);

  return _WaterSetup(
    database,
    LocalWaterRepository(
      LocalWaterDatasource(
        database: database,
        clock: const _FixedClock(),
        userId: userId,
      ),
    ),
  );
}

WaterRecord _record({required String id, DateTime? date, int amount = 250}) {
  return WaterRecord(
    id: id,
    amount: WaterAmount.create(amount)!,
    recordedAt: date ?? DateTime(2026, 7, 9),
    clock: const _FixedClock(),
  );
}

class _WaterSetup {
  const _WaterSetup(this.database, this.repository);

  final LocalDatabase database;
  final LocalWaterRepository repository;
}

class _FixedClock implements ClockService {
  const _FixedClock();

  @override
  DateTime now() => DateTime(2026, 7, 9, 12);
}
