import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/consistency/appointment_local_consistency_checker.dart';
import 'package:helpbari/core/database/drift/cutover/appointment_cutover_service.dart';
import 'package:helpbari/core/database/drift/migrations/appointment_legacy_service.dart';
import 'package:helpbari/core/database/local_database_record.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/appointments/data/datasources/drift_appointment_local_datasource.dart';
import 'package:helpbari/features/appointments/data/dtos/appointment_dto.dart';
import 'package:helpbari/features/appointments/domain/value_objects/value_objects.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 7, 12, 12);
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());
  test('CRUD, tombstone, conflict and anonymous isolation', () async {
    final local = DriftAppointmentLocalDatasource(
      dao: database.appointmentDao,
      clock: _Clock(now),
      userId: 'user-1',
    );
    await local.save(_dto(now));
    expect(await local.getAll(), hasLength(1));
    await local.applyRemoteAndMarkSynced(
      _dto(now.add(const Duration(minutes: 1)), title: 'Retorno'),
    );
    expect((await local.getAll()).single.title, 'Retorno');
    expect(
      (await local.getAll()).single.syncMetadata.syncStatus,
      SyncStatus.synced,
    );
    await local.applyRemote(_dto(now, title: 'Antigo'));
    expect((await local.getAll()).single.title, 'Retorno');
    await local.delete('appointment-1');
    expect(await local.getAll(), isEmpty);
    expect(
      (await local.pendingSync()).single.syncMetadata.syncStatus,
      SyncStatus.pendingDelete,
    );
    final anonymous = DriftAppointmentLocalDatasource(
      dao: database.appointmentDao,
      clock: _Clock(now),
      userId: anonymousAppointmentUserId,
    );
    await anonymous.save(_dto(now));
    expect(await anonymous.pendingSync(), isEmpty);
  });
  test('legacy is preserved and cutover is idempotent per user', () async {
    final storage = _Storage();
    final record = LocalDatabaseRecord(
      metadata: SyncMetadata(
        id: 'legacy',
        userId: 'user-1',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
      ),
      data: {
        'title': 'Consulta',
        'date': now.toIso8601String(),
        'status': 'scheduled',
        'doctorName': null,
        'location': null,
        'notes': null,
      },
    );
    storage.legacy = jsonEncode([record.toJson()]);
    final original = storage.legacy;
    await AppointmentLegacyService(
      database: database,
      storage: storage,
    ).migrate();
    await AppointmentLegacyService(
      database: database,
      storage: storage,
    ).migrate();
    expect(
      await database.appointmentDao.getActiveByUser('user-1'),
      hasLength(1),
    );
    expect(storage.legacy, original);
    expect(
      (await AppointmentLocalConsistencyChecker(
        database: database,
        storage: storage,
      ).check(userId: 'user-1')).consistent,
      isTrue,
    );
    final cutover = AppointmentCutoverService(
      database: database,
      storage: storage,
    );
    expect(await cutover.attempt('user-1'), isTrue);
    expect(await cutover.attempt('user-1'), isTrue);
    expect(await cutover.attempt(anonymousAppointmentUserId), isFalse);
    expect(await cutover.isCompleted('user-2'), isFalse);
    expect(storage.legacy, original);
  });
}

AppointmentDto _dto(DateTime updatedAt, {String title = 'Consulta'}) =>
    AppointmentDto(
      id: 'appointment-1',
      title: title,
      date: DateTime.utc(2026, 8, 1),
      status: AppointmentStatus.scheduled,
      syncMetadata: SyncMetadata(
        id: 'appointment-1',
        userId: 'user-1',
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: updatedAt,
        syncStatus: SyncStatus.pendingCreate,
      ),
    );

class _Clock implements ClockService {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

class _Storage implements LocalStorageService {
  String? legacy;
  final values = <String, String>{};
  @override
  bool? getBool(String key) => null;
  @override
  String? getString(String key) =>
      key == appointmentLegacyStorageKey ? legacy : values[key];
  @override
  Future<void> setBool(String key, bool value) async {}
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
