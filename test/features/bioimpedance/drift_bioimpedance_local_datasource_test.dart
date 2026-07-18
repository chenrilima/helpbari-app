import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart'
    hide BioimpedanceRecord;
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/bioimpedance/data/datasources/drift_bioimpedance_local_datasource.dart';
import 'package:helpbari/features/bioimpedance/data/dtos/bioimpedance_record_dto.dart';
import 'package:helpbari/features/bioimpedance/domain/entities/bioimpedance_record.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 7, 17, 12);

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test(
    'saves, tombstones and preserves additional metrics while excluding anonymous from sync',
    () async {
      final datasource = DriftBioimpedanceLocalDatasource(
        dao: database.bioimpedanceDao,
        clock: _FixedClock(now),
        userId: 'user-1',
      );

      await datasource.save(_record(now));

      final saved = (await datasource.getHistory()).single;
      expect(saved.weightKg, 82.4);
      expect(saved.additionalMetrics['phaseAngle']?.numericValue, 5.6);
      expect(
        (await datasource.pendingSync()).single.syncMetadata.syncStatus,
        SyncStatus.pendingCreate,
      );

      await datasource.delete('bio-1');

      expect(await datasource.getHistory(), isEmpty);
      expect(
        (await datasource.pendingSync()).single.syncMetadata.syncStatus,
        SyncStatus.pendingDelete,
      );

      final anonymous = DriftBioimpedanceLocalDatasource(
        dao: database.bioimpedanceDao,
        clock: _FixedClock(now),
        userId: anonymousBioimpedanceUserId,
      );
      await anonymous.save(_record(now, userId: anonymousBioimpedanceUserId));
      expect(await anonymous.pendingSync(), isEmpty);
    },
  );

  test('latest updatedAt wins during remote application', () async {
    final datasource = DriftBioimpedanceLocalDatasource(
      dao: database.bioimpedanceDao,
      clock: _FixedClock(now),
      userId: 'user-1',
    );

    await datasource.save(_record(now));
    await datasource.applyRemoteAndMarkSynced(
      _dtoRecord(now.add(const Duration(minutes: 1)), weightKg: 79.9),
    );

    expect((await datasource.getHistory()).single.weightKg, 79.9);
    expect(
      (await datasource.pendingById('bio-1'))?.syncMetadata.syncStatus,
      SyncStatus.synced,
    );

    await datasource.applyRemote(
      _dtoRecord(now.subtract(const Duration(minutes: 1)), weightKg: 60),
    );

    expect((await datasource.getHistory()).single.weightKg, 79.9);
  });
}

BioimpedanceRecord _record(
  DateTime now, {
  String userId = 'user-1',
  double weightKg = 82.4,
}) => BioimpedanceRecord(
  id: 'bio-1',
  userId: userId,
  measuredAt: DateTime.utc(2026, 7, 17, 8),
  weightKg: weightKg,
  muscleMassKg: 31.2,
  source: BioimpedanceRecordSource.manual,
  additionalMetrics: const {
    'phaseAngle': BioimpedanceAdditionalMetric(
      key: 'phaseAngle',
      label: 'Ângulo de fase',
      originalValue: '5.6',
      numericValue: 5.6,
      unit: 'graus',
      source: BioimpedanceMetricSource.manual,
    ),
  },
  createdAt: now,
  updatedAt: now,
  syncStatus: SyncStatus.pendingCreate,
);

BioimpedanceRecordDto _dtoRecord(
  DateTime updatedAt, {
  required double weightKg,
}) => BioimpedanceRecordDto.fromEntity(
  _record(updatedAt, weightKg: weightKg),
  now: updatedAt,
  previousMetadata: SyncMetadata(
    id: 'bio-1',
    userId: 'user-1',
    createdAt: nowBase,
    updatedAt: updatedAt,
    syncStatus: SyncStatus.pendingUpdate,
  ),
);

final nowBase = DateTime.utc(2026, 7, 1);

class _FixedClock implements ClockService {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
