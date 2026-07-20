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
  int calls = 0;

  @override
  String generate() {
    calls++;
    return '00000000-0000-4000-8000-${calls.toString().padLeft(12, '0')}';
  }
}

class _EmptyUuid implements UuidService {
  @override
  String generate() => '';
}

void main() {
  test(
    'daily logs upsert by user, vitamin and date and isolate users',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final day = DateTime(2026, 7, 12);
      final uuid = _Uuid();
      final userA = DriftVitaminLogLocalDatasource(
        dao: db.vitaminLogDao,
        clock: _Clock(day),
        uuid: uuid,
        userId: 'user-a',
      );
      final created = await userA.setStatus(
        vitaminId: 'vitamin-1',
        date: day,
        status: VitaminStatus.taken,
      );
      final updated = await userA.setStatus(
        vitaminId: 'vitamin-1',
        date: day,
        status: VitaminStatus.skipped,
      );
      expect(
        created.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-8[0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(created.syncMetadata.id, created.id);
      expect(updated.id, created.id);
      expect(updated.syncMetadata.id, created.id);
      expect(uuid.calls, 1);
      expect(await userA.getByPeriod(day, day), hasLength(1));
      expect(
        (await userA.getByPeriod(day, day)).single.status,
        VitaminStatus.skipped,
      );
      final userB = DriftVitaminLogLocalDatasource(
        dao: db.vitaminLogDao,
        clock: _Clock(day),
        uuid: _Uuid(),
        userId: 'user-b',
      );
      expect(await userB.getByPeriod(day, day), isEmpty);
      final otherUserLog = await userB.setStatus(
        vitaminId: 'vitamin-1',
        date: day,
        status: VitaminStatus.taken,
      );
      expect(otherUserLog.id, created.id);
      expect(await userA.getByPeriod(day, day), hasLength(1));
      expect(await userB.getByPeriod(day, day), hasLength(1));
    },
  );

  test(
    'preserves one id through pending, retry, tombstone and remote payload',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final day = DateTime(2026, 7, 12);
      final uuid = _Uuid();
      final local = DriftVitaminLogLocalDatasource(
        dao: db.vitaminLogDao,
        clock: _Clock(day),
        uuid: uuid,
        userId: 'user-a',
      );

      final created = await local.setStatus(
        vitaminId: 'vitamin-1',
        date: day,
        status: VitaminStatus.taken,
      );
      final reset = await local.setStatus(
        vitaminId: 'vitamin-1',
        date: day,
        status: VitaminStatus.pending,
      );
      final drift = (await local.getByPeriod(day, day)).single;
      final pending = (await local.pendingSync()).single;

      expect(reset.id, created.id);
      expect(drift.id, created.id);
      expect(drift.syncMetadata.id, created.id);
      expect(pending.id, created.id);
      expect(pending.syncMetadata.id, created.id);
      expect(pending.toSupabaseRow(userId: 'user-a')['id'], created.id);
      expect(uuid.calls, 1);

      await local.markFailed(created.id, 'offline');
      final retry = await local.pendingById(created.id);
      expect(retry?.id, created.id);
      expect(retry?.syncMetadata.id, created.id);

      await local.deleteForVitamin('vitamin-1');
      final tombstone = await local.pendingById(created.id);
      expect(tombstone?.id, created.id);
      expect(tombstone?.syncMetadata.id, created.id);
      expect(tombstone?.syncMetadata.isDeleted, isTrue);
      expect(uuid.calls, 1);
    },
  );

  test('anonymous never exposes vitamin log operations for sync', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final local = DriftVitaminLogLocalDatasource(
      dao: db.vitaminLogDao,
      clock: _Clock(DateTime(2026, 7, 12)),
      uuid: _Uuid(),
      userId: 'anonymous',
    );
    await local.setStatus(
      vitaminId: 'vitamin-1',
      date: DateTime(2026, 7, 12),
      status: VitaminStatus.taken,
    );
    expect(await local.pendingSync(), isEmpty);
  });

  test(
    'rejects an empty generated identity without persisting a log',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final day = DateTime(2026, 7, 12);
      final local = DriftVitaminLogLocalDatasource(
        dao: db.vitaminLogDao,
        clock: _Clock(day),
        uuid: _EmptyUuid(),
        userId: 'user-a',
      );

      await expectLater(
        local.setStatus(
          vitaminId: 'vitamin-1',
          date: day,
          status: VitaminStatus.taken,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await local.getByPeriod(day, day), isEmpty);
    },
  );
}
