import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/uuid_service.dart';
import 'package:helpbari/features/vitamins/data/datasources/drift_vitamin_log_local_datasource.dart';
import 'package:helpbari/features/vitamins/domain/value_objects/vitamin_status.dart';

class _Clock implements ClockService {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

class _Uuid implements UuidService {
  const _Uuid();
  @override
  String generate() => '00000000-0000-4000-8000-000000000001';
}

void main() {
  test(
    'daily logs upsert by user, vitamin and date and isolate users',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final day = DateTime(2026, 7, 12);
      final userA = DriftVitaminLogLocalDatasource(
        dao: db.vitaminLogDao,
        clock: _Clock(day),
        uuid: const _Uuid(),
        userId: 'user-a',
      );
      await userA.setStatus(
        vitaminId: 'vitamin-1',
        date: day,
        status: VitaminStatus.taken,
      );
      await userA.setStatus(
        vitaminId: 'vitamin-1',
        date: day,
        status: VitaminStatus.skipped,
      );
      expect(await userA.getByPeriod(day, day), hasLength(1));
      expect(
        (await userA.getByPeriod(day, day)).single.status,
        VitaminStatus.skipped,
      );
      final userB = DriftVitaminLogLocalDatasource(
        dao: db.vitaminLogDao,
        clock: _Clock(day),
        uuid: const _Uuid(),
        userId: 'user-b',
      );
      expect(await userB.getByPeriod(day, day), isEmpty);
    },
  );

  test('anonymous never exposes vitamin log operations for sync', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final local = DriftVitaminLogLocalDatasource(
      dao: db.vitaminLogDao,
      clock: _Clock(DateTime(2026, 7, 12)),
      uuid: const _Uuid(),
      userId: 'anonymous',
    );
    await local.setStatus(
      vitaminId: 'vitamin-1',
      date: DateTime(2026, 7, 12),
      status: VitaminStatus.taken,
    );
    expect(await local.pendingSync(), isEmpty);
  });
}
