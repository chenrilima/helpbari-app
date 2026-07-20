import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/time/iana_timezone_bootstrap.dart';
import 'package:helpbari/features/smart_routines/application/unified_treatment_cutover_service.dart';
import 'package:helpbari/features/smart_routines/application/unified_treatment_migrator.dart';
import 'package:helpbari/features/smart_routines/application/unified_treatment_rollout.dart';

void main() {
  setUpAll(IanaTimezoneBootstrap.initialize);

  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test(
    'migrates medication and vitamin idempotently without pending event',
    () async {
      final now = DateTime.utc(2026, 7, 20, 12);
      await _consent(database, now);
      await database
          .into(database.medicationRecords)
          .insert(
            MedicationRecordsCompanion.insert(
              id: '11111111-1111-4111-8111-111111111111',
              userId: 'user-a',
              name: 'Medication A',
              scheduleHour: 8,
              scheduleMinute: 30,
              dosage: const Value('20 mg'),
              notes: const Value('note'),
              createdAt: now,
              updatedAt: now,
              syncStatus: 'synced',
            ),
          );
      await database
          .into(database.medicationLogRecords)
          .insert(
            MedicationLogRecordsCompanion.insert(
              id: '21111111-1111-4111-8111-111111111111',
              userId: 'user-a',
              medicationId: '11111111-1111-4111-8111-111111111111',
              logDate: DateTime(2026, 7, 19),
              status: 'pending',
              createdAt: now,
              updatedAt: now,
              syncStatus: 'synced',
            ),
          );
      await database
          .into(database.vitaminRecords)
          .insert(
            VitaminRecordsCompanion.insert(
              id: '31111111-1111-4111-8111-111111111111',
              userId: 'user-a',
              name: 'Vitamin A',
              scheduleHour: 9,
              scheduleMinute: 0,
              createdAt: now,
              updatedAt: now,
              syncStatus: 'synced',
            ),
          );
      await database
          .into(database.vitaminLogRecords)
          .insert(
            VitaminLogRecordsCompanion.insert(
              id: '41111111-1111-4111-8111-111111111111',
              userId: 'user-a',
              vitaminId: '31111111-1111-4111-8111-111111111111',
              logDate: DateTime(2026, 7, 19),
              status: 'taken',
              createdAt: now,
              updatedAt: now,
              syncStatus: 'synced',
            ),
          );

      final migrator = UnifiedTreatmentMigrator(database: database);
      final first = await migrator.migrate(userId: 'user-a', startedAtUtc: now);
      final second = await migrator.migrate(
        userId: 'user-a',
        startedAtUtc: now,
      );

      expect(first.migrated, 2);
      expect(second.alreadyMigrated, 2);
      expect(
        await database.select(database.smartRoutineRecords).get(),
        hasLength(2),
      );
      expect(
        await database.select(database.routinePlanRecords).get(),
        hasLength(2),
      );
      expect(
        await database.select(database.routineScheduleRecords).get(),
        hasLength(2),
      );
      expect(
        await database.select(database.routineOccurrenceRecords).get(),
        hasLength(2),
      );
      final events = await database
          .select(database.routineAdherenceEventRecords)
          .get();
      expect(events, hasLength(1));
      expect(events.single.type, 'taken');
      final plans = await database.select(database.routinePlanRecords).get();
      expect(plans.map((value) => value.durationType), everyElement('unknown'));
      expect(
        plans.map((value) => value.temporalPrecision),
        everyElement('estimatedFromLegacyDate'),
      );
    },
  );

  test(
    'missing trusted timezone requires validation and blocks cutover',
    () async {
      final now = DateTime.utc(2026, 7, 20);
      await database
          .into(database.vitaminRecords)
          .insert(
            VitaminRecordsCompanion.insert(
              id: '51111111-1111-4111-8111-111111111111',
              userId: 'user-a',
              name: 'Vitamin A',
              scheduleHour: 9,
              scheduleMinute: 0,
              createdAt: now,
              updatedAt: now,
              syncStatus: 'synced',
            ),
          );
      final result = await UnifiedTreatmentMigrator(
        database: database,
      ).migrate(userId: 'user-a', startedAtUtc: now);
      expect(result.validationRequired, 1);
      final cutover = UnifiedTreatmentCutoverService(
        database: database,
        rollout: UnifiedTreatmentRolloutRepository(database),
      );
      expect(
        await cutover.attempt(userId: 'user-a', evaluatedAtUtc: now),
        isFalse,
      );
      expect(
        await UnifiedTreatmentRolloutRepository(database).stateFor('user-a'),
        UnifiedTreatmentCutoverPhase.legacyRead,
      );
      expect(
        await cutover.prepareMigration(userId: 'user-a', evaluatedAtUtc: now),
        isTrue,
      );
      expect(
        await cutover.attempt(userId: 'user-a', evaluatedAtUtc: now),
        isFalse,
      );
      expect(
        await UnifiedTreatmentRolloutRepository(database).stateFor('user-a'),
        UnifiedTreatmentCutoverPhase.validationRequired,
      );
    },
  );

  test(
    'cutover cannot skip migration and rollback stops after new writes',
    () async {
      final now = DateTime.utc(2026, 7, 20, 12);
      await _consent(database, now);
      await database
          .into(database.vitaminRecords)
          .insert(
            VitaminRecordsCompanion.insert(
              id: '71111111-1111-4111-8111-111111111111',
              userId: 'user-a',
              name: 'Vitamin B',
              scheduleHour: 9,
              scheduleMinute: 0,
              createdAt: now,
              updatedAt: now,
              syncStatus: 'synced',
            ),
          );
      final rollout = UnifiedTreatmentRolloutRepository(database);
      final cutover = UnifiedTreatmentCutoverService(
        database: database,
        rollout: rollout,
      );

      expect(
        await cutover.attempt(userId: 'user-a', evaluatedAtUtc: now),
        isFalse,
      );
      expect(
        await cutover.prepareMigration(userId: 'user-a', evaluatedAtUtc: now),
        isTrue,
      );
      await UnifiedTreatmentMigrator(
        database: database,
      ).migrate(userId: 'user-a', startedAtUtc: now);
      expect(
        await cutover.attempt(userId: 'user-a', evaluatedAtUtc: now),
        isTrue,
      );
      expect(
        await rollout.stateFor('user-a'),
        UnifiedTreatmentCutoverPhase.readNew,
      );
      expect(
        await cutover.rollbackReadBeforeNewWrites(
          userId: 'user-a',
          evaluatedAtUtc: now,
        ),
        isTrue,
      );
      expect(
        await rollout.stateFor('user-a'),
        UnifiedTreatmentCutoverPhase.legacyRead,
      );

      await cutover.prepareMigration(userId: 'user-a', evaluatedAtUtc: now);
      expect(
        await cutover.attempt(userId: 'user-a', evaluatedAtUtc: now),
        isTrue,
      );
      expect(
        await cutover.enableNewWrites(userId: 'user-a', evaluatedAtUtc: now),
        isTrue,
      );
      expect(
        await cutover.rollbackReadBeforeNewWrites(
          userId: 'user-a',
          evaluatedAtUtc: now,
        ),
        isFalse,
      );
      expect(
        await rollout.stateFor('user-a'),
        UnifiedTreatmentCutoverPhase.writeNew,
      );
    },
  );
}

Future<void> _consent(AppDatabase database, DateTime now) => database
    .into(database.privacyConsentRecords)
    .insert(
      PrivacyConsentRecordsCompanion.insert(
        id: '61111111-1111-4111-8111-111111111111',
        userId: 'user-a',
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
