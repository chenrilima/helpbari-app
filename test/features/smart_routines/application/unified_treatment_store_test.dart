import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/time/iana_timezone_bootstrap.dart';
import 'package:helpbari/features/smart_routines/application/unified_treatment_store.dart';
import 'package:helpbari/features/smart_routines/domain/enums/routine_enums.dart';
import 'package:helpbari/features/smart_routines/domain/value_objects/local_date.dart';
import 'package:helpbari/features/smart_routines/domain/value_objects/routine_values.dart';

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

  test('active catalog returns only the latest plan revision', () async {
    const treatmentId = '51111111-1111-4111-8111-111111111111';
    await store.save(
      kind: TreatmentSpecialization.medication,
      value: const TreatmentProjection(
        id: treatmentId,
        name: 'Medication A',
        hour: 8,
        minute: 0,
        dosage: '10 mg',
      ),
    );
    await store.save(
      kind: TreatmentSpecialization.medication,
      value: const TreatmentProjection(
        id: treatmentId,
        name: 'Medication A',
        hour: 9,
        minute: 0,
        dosage: '20 mg',
      ),
    );

    final catalog = await store.list(TreatmentSpecialization.medication);

    expect(catalog, hasLength(1));
    expect(catalog.single.hour, 9);
    expect(catalog.single.dosage, '20 mg');
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

  test(
    'advanced write preserves revisions and supports multiple weekdays',
    () async {
      const treatmentId = '61111111-1111-4111-8111-111111111111';
      final start = LocalDate(year: 2026, month: 7, day: 21);
      await store.write(
        TreatmentWriteCommand(
          id: treatmentId,
          name: 'Suplemento A',
          category: RoutineCategory.supplement,
          mode: RoutinePlanMode.scheduled,
          durationType: PlanDurationType.unknown,
          effectiveFrom: start,
          weekdays: const {DateTime.monday, DateTime.wednesday},
          schedules: [
            TreatmentScheduleInput(time: TimeOfDayValue(hour: 8, minute: 0)),
            TreatmentScheduleInput(
              time: TimeOfDayValue(hour: 20, minute: 0),
              reminderEnabled: false,
            ),
          ],
        ),
      );
      await store.write(
        TreatmentWriteCommand(
          id: treatmentId,
          name: 'Suplemento A',
          category: RoutineCategory.supplement,
          mode: RoutinePlanMode.scheduled,
          durationType: PlanDurationType.continuous,
          effectiveFrom: start.addDays(1),
          schedules: [
            TreatmentScheduleInput(time: TimeOfDayValue(hour: 9, minute: 0)),
          ],
        ),
      );

      final plans = await database.select(database.routinePlanRecords).get();
      expect(plans, hasLength(2));
      expect(plans.first.replacedAt, isNot(null));
      expect(plans.last.previousPlanId, plans.first.id);
      final item = (await store.listItems()).single;
      expect(item.category, RoutineCategory.supplement);
      expect(item.durationType, PlanDurationType.continuous);
      expect(item.schedules.single.time, TimeOfDayValue(hour: 9, minute: 0));
    },
  );

  test(
    'PRN creates no recurring times and lifecycle preserves history',
    () async {
      const treatmentId = '71111111-1111-4111-8111-111111111111';
      await store.write(
        TreatmentWriteCommand(
          id: treatmentId,
          name: 'Uso quando necessário',
          category: RoutineCategory.other,
          mode: RoutinePlanMode.asNeeded,
          durationType: PlanDurationType.unknown,
          effectiveFrom: LocalDate(year: 2026, month: 7, day: 21),
          schedules: const [],
        ),
      );

      expect((await store.listItems()).single.schedules, isEmpty);
      await store.pause(treatmentId);
      expect((await store.listItems()).single.status, RoutineStatus.paused);
      await store.resume(treatmentId);
      expect((await store.listItems()).single.status, RoutineStatus.active);
      expect(
        await database.select(database.routinePauseRecords).get(),
        hasLength(1),
      );
      await store.complete(treatmentId);
      expect((await store.listItems()).single.status, RoutineStatus.completed);
      await store.softDelete(treatmentId);
      expect(await store.listItems(), isEmpty);
      expect(
        await database.select(database.routinePlanRecords).get(),
        isNotEmpty,
      );
    },
  );

  test('PRN use stores ad hoc occurrence, used time and observation', () async {
    const treatmentId = '81111111-1111-4111-8111-111111111111';
    await store.write(
      TreatmentWriteCommand(
        id: treatmentId,
        name: 'Uso eventual',
        category: RoutineCategory.medication,
        mode: RoutinePlanMode.asNeeded,
        durationType: PlanDurationType.unknown,
        effectiveFrom: LocalDate(year: 2026, month: 7, day: 20),
        schedules: const [],
      ),
    );
    final usedAt = DateTime.utc(2026, 7, 20, 9, 45);

    await store.registerPrnUse(
      routineId: treatmentId,
      occurredAt: usedAt,
      note: 'Observação do uso',
    );

    final occurrence =
        (await database.select(database.routineOccurrenceRecords).get()).single;
    final event =
        (await database.select(database.routineAdherenceEventRecords).get())
            .single;
    expect(occurrence.origin, RoutineOccurrenceOrigin.adHocAsNeeded.name);
    expect(occurrence.expectationKind, 'asNeeded');
    expect(event.occurredAtUtc.toUtc(), usedAt.toUtc());
    expect(event.note, 'Observação do uso');
    final detail = await store.detail(treatmentId);
    expect(detail.events.single.note, 'Observação do uso');
    expect(detail.conflicts, isEmpty);
  });

  test('conflicting terminal events require explicit resolution', () async {
    const treatmentId = '91111111-1111-4111-8111-111111111111';
    await store.write(
      TreatmentWriteCommand(
        id: treatmentId,
        name: 'Uso eventual',
        category: RoutineCategory.other,
        mode: RoutinePlanMode.asNeeded,
        durationType: PlanDurationType.unknown,
        effectiveFrom: LocalDate(year: 2026, month: 7, day: 20),
        schedules: const [],
      ),
    );
    await store.registerPrnUse(routineId: treatmentId, occurredAt: now);
    final taken =
        (await database.select(database.routineAdherenceEventRecords).get())
            .single;
    await database
        .into(database.routineAdherenceEventRecords)
        .insert(
          taken
              .toCompanion(true)
              .copyWith(
                id: const Value('92222222-2222-4222-8222-222222222222'),
                type: const Value('skipped'),
                syncStatus: const Value('synced'),
              ),
        );

    final conflicted = await store.detail(treatmentId);
    expect(conflicted.conflicts, hasLength(1));
    expect(conflicted.conflicts.single.versions, hasLength(2));

    await store.resolveConflict(
      occurrenceId: taken.occurrenceId,
      keepEventId: taken.id,
    );

    final resolved = await store.detail(treatmentId);
    expect(resolved.conflicts, isEmpty);
    expect(
      resolved.events.where((event) => event.type == 'correction'),
      hasLength(1),
    );
  });
}

final class _FixedClock implements ClockService {
  const _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime now() => value;
}
