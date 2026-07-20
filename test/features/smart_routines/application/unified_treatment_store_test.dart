import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/time/iana_timezone_bootstrap.dart';
import 'package:helpbari/features/smart_routines/application/unified_treatment_store.dart';

void main() {
  setUpAll(IanaTimezoneBootstrap.initialize);

  late AppDatabase database;
  late UnifiedTreatmentStore store;
  const userId = 'user-a';
  final now = DateTime.utc(2026, 7, 20, 12);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    store = UnifiedTreatmentStore(
      database: database,
      clock: _FixedClock(now),
      userId: userId,
    );
    await database
        .into(database.privacyConsentRecords)
        .insert(
          PrivacyConsentRecordsCompanion.insert(
            id: '61111111-1111-4111-8111-111111111111',
            userId: userId,
            termsVersion: '1',
            privacyVersion: '1',
            acceptedAt: now,
            deviceId: 'device',
            timezone: 'America/Sao_Paulo',
            createdAt: now,
            updatedAt: now,
            syncStatus: 'synced',
          ),
        );
  });

  tearDown(() => database.close());

  test(
    'taken can be invalidated and recorded again without rewriting history',
    () async {
      const treatmentId = '11111111-1111-4111-8111-111111111111';
      await store.save(
        kind: TreatmentSpecialization.medication,
        value: const TreatmentProjection(
          id: treatmentId,
          name: 'Medication A',
          hour: 8,
          minute: 30,
        ),
      );

      await store.setDailyState(
        kind: TreatmentSpecialization.medication,
        treatmentId: treatmentId,
        date: now,
        state: TreatmentDailyState.taken,
      );
      await store.setDailyState(
        kind: TreatmentSpecialization.medication,
        treatmentId: treatmentId,
        date: now,
        state: TreatmentDailyState.pending,
      );
      await store.setDailyState(
        kind: TreatmentSpecialization.medication,
        treatmentId: treatmentId,
        date: now,
        state: TreatmentDailyState.taken,
      );

      final events = await database
          .select(database.routineAdherenceEventRecords)
          .get();
      expect(events, hasLength(3));
      expect(events.where((event) => event.type == 'taken'), hasLength(2));
      final logs = await store.logs(
        TreatmentSpecialization.medication,
        now,
        now,
      );
      expect(logs.single.state, TreatmentDailyState.taken);
    },
  );

  test('activated schedule rejects an in-place clinical mutation', () async {
    const treatmentId = '21111111-1111-4111-8111-111111111111';
    await store.save(
      kind: TreatmentSpecialization.vitamin,
      value: const TreatmentProjection(
        id: treatmentId,
        name: 'Vitamin A',
        hour: 9,
        minute: 0,
      ),
    );
    final schedule =
        (await database.select(database.routineScheduleRecords).get()).single;
    final changed = schedule
        .toCompanion(true)
        .copyWith(
          ruleJson: const Value(
            '{"schemaVersion":1,"type":"dailyAtTimes","times":["10:00"]}',
          ),
        );

    await expectLater(
      database.smartRoutineDao.upsertSchedule(changed),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'routine_schedule_payload_conflict',
        ),
      ),
    );
    expect(
      (await database.select(database.routineScheduleRecords).get())
          .single
          .ruleJson,
      schedule.ruleJson,
    );
  });

  test(
    'clinical date lookup is timezone-safe and pause blocks an event',
    () async {
      const treatmentId = '31111111-1111-4111-8111-111111111111';
      await store.save(
        kind: TreatmentSpecialization.medication,
        value: const TreatmentProjection(
          id: treatmentId,
          name: 'Medication B',
          hour: 23,
          minute: 30,
        ),
      );
      await store.setDailyState(
        kind: TreatmentSpecialization.medication,
        treatmentId: treatmentId,
        date: now,
        state: TreatmentDailyState.taken,
      );

      final logs = await store.logs(
        TreatmentSpecialization.medication,
        now,
        now,
      );
      expect(logs.single.date, DateTime(2026, 7, 20));
      final occurrence =
          (await database.select(database.routineOccurrenceRecords).get())
              .single;
      expect(occurrence.originalScheduledFor.toUtc().day, 21);

      await database
          .into(database.routinePauseRecords)
          .insert(
            RoutinePauseRecordsCompanion.insert(
              id: '41111111-1111-4111-8111-111111111111',
              userId: userId,
              routineId: treatmentId,
              scope: 'routine',
              startsAt: DateTime.utc(2026, 7, 22, 2),
              endsAt: Value(DateTime.utc(2026, 7, 22, 4)),
              createdAt: now,
              updatedAt: now,
              syncStatus: 'pendingCreate',
            ),
          );

      await expectLater(
        store.setDailyState(
          kind: TreatmentSpecialization.medication,
          treatmentId: treatmentId,
          date: DateTime(2026, 7, 21),
          state: TreatmentDailyState.taken,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'routine_paused_at_occurrence',
          ),
        ),
      );
    },
  );
}

final class _FixedClock implements ClockService {
  const _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime now() => value;
}
