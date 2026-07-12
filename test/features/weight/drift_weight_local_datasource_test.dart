import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/weight/data/datasources/drift_weight_local_datasource.dart';
import 'package:helpbari/features/weight/data/dtos/weight_record_dto.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 7, 12, 12);

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test(
    'creates, updates, tombstones and excludes anonymous from sync',
    () async {
      final datasource = DriftWeightLocalDatasource(
        dao: database.weightDao,
        clock: _FixedClock(now),
        userId: 'user-1',
      );
      await datasource.save(_dto(now));
      expect(await datasource.getHistory(), hasLength(1));
      expect(
        (await datasource.pendingSync()).single.syncMetadata.syncStatus,
        SyncStatus.pendingCreate,
      );

      await datasource.delete('weight-1');
      expect(await datasource.getHistory(), isEmpty);
      expect(
        (await datasource.pendingSync()).single.syncMetadata.syncStatus,
        SyncStatus.pendingDelete,
      );

      final anonymous = DriftWeightLocalDatasource(
        dao: database.weightDao,
        clock: _FixedClock(now),
        userId: anonymousWeightUserId,
      );
      await anonymous.save(_dto(now));
      expect(await anonymous.pendingSync(), isEmpty);
    },
  );

  test(
    'latest updatedAt wins and remote application is transactional',
    () async {
      final datasource = DriftWeightLocalDatasource(
        dao: database.weightDao,
        clock: _FixedClock(now),
        userId: 'user-1',
      );
      await datasource.save(_dto(now));
      await datasource.applyRemoteAndMarkSynced(
        _dto(now.add(const Duration(minutes: 1)), weight: 88),
      );
      final record = (await datasource.getHistory()).single;
      expect(record.weight, 88);
      expect(record.syncMetadata.syncStatus, SyncStatus.synced);

      await datasource.applyRemote(_dto(now, weight: 70));
      expect((await datasource.getHistory()).single.weight, 88);
    },
  );
}

WeightRecordDto _dto(DateTime updatedAt, {double weight = 90}) =>
    WeightRecordDto(
      id: 'weight-1',
      weight: weight,
      recordedAt: DateTime.utc(2026, 7, 12),
      notes: 'ok',
      syncMetadata: SyncMetadata(
        id: 'weight-1',
        userId: 'user-1',
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: updatedAt,
        syncStatus: SyncStatus.pendingCreate,
      ),
    );

class _FixedClock implements ClockService {
  const _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}
