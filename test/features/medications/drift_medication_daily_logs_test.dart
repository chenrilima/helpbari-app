import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/uuid_service.dart';
import 'package:helpbari/features/medications/data/datasources/drift_medication_log_local_datasource.dart';
import 'package:helpbari/features/medications/domain/value_objects/medication_status.dart';

class _Clock implements ClockService {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

class _Uuid implements UuidService {
  const _Uuid();
  @override
  String generate() => '00000000-0000-4000-8000-000000000002';
}

void main() {
  test('upserts one daily status and isolates users', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final day = DateTime(2026, 7, 15);
    final userA = DriftMedicationLogLocalDatasource(
      dao: db.medicationLogDao,
      clock: _Clock(day),
      uuid: const _Uuid(),
      userId: 'user-a',
    );
    await userA.setStatus(
      medicationId: 'med-1',
      date: day,
      status: MedicationStatus.taken,
    );
    await userA.setStatus(
      medicationId: 'med-1',
      date: day,
      status: MedicationStatus.skipped,
    );
    final logs = await userA.getByPeriod(day, day);
    expect(logs, hasLength(1));
    expect(logs.single.status, MedicationStatus.skipped);
    final userB = DriftMedicationLogLocalDatasource(
      dao: db.medicationLogDao,
      clock: _Clock(day),
      uuid: const _Uuid(),
      userId: 'user-b',
    );
    expect(await userB.getByPeriod(day, day), isEmpty);
  });
  test('anonymous never exposes medication logs to sync', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final day = DateTime(2026, 7, 15);
    final local = DriftMedicationLogLocalDatasource(
      dao: db.medicationLogDao,
      clock: _Clock(day),
      uuid: const _Uuid(),
      userId: 'anonymous',
    );
    await local.setStatus(
      medicationId: 'med-1',
      date: day,
      status: MedicationStatus.taken,
    );
    expect(await local.pendingSync(), isEmpty);
  });
}
