import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/database/drift/app_database.dart';
import '../domain/services/unified_treatment_identity_generator.dart';

enum UnifiedTreatmentMigrationStatus {
  notStarted,
  detected,
  migrating,
  validationRequired,
  completed,
  failed,
  conflict,
}

final class UnifiedTreatmentMigrationResult {
  const UnifiedTreatmentMigrationResult({
    required this.detected,
    required this.migrated,
    required this.alreadyMigrated,
    required this.validationRequired,
    required this.failed,
    required this.duration,
  });

  final int detected;
  final int migrated;
  final int alreadyMigrated;
  final int validationRequired;
  final int failed;
  final Duration duration;
}

/// Local-first shadow migration. Each legacy entity is its own transaction,
/// so retry resumes at the first incomplete mapping without duplicating rows.
final class UnifiedTreatmentMigrator {
  const UnifiedTreatmentMigrator({
    required this.database,
    this.identity = const UnifiedTreatmentIdentityGenerator(),
  });

  final AppDatabase database;
  final UnifiedTreatmentIdentityGenerator identity;
  static const migrationSchemaVersion = 1;

  Future<UnifiedTreatmentMigrationResult> migrate({
    required String userId,
    required DateTime startedAtUtc,
  }) async {
    if (userId.isEmpty || userId == 'anonymous' || !startedAtUtc.isUtc) {
      throw ArgumentError('Authenticated user and UTC clock are required.');
    }
    final stopwatch = Stopwatch()..start();
    final timeZone = await _trustedTimeZone(userId);
    final medications = await (database.select(
      database.medicationRecords,
    )..where((row) => row.userId.equals(userId))).get();
    final vitamins = await (database.select(
      database.vitaminRecords,
    )..where((row) => row.userId.equals(userId))).get();
    var migrated = 0;
    var already = 0;
    var validationRequired = 0;
    var failed = 0;

    for (final item in medications) {
      final result = await _migrateMedication(item, timeZone, startedAtUtc);
      switch (result) {
        case _ItemResult.migrated:
          migrated++;
        case _ItemResult.alreadyMigrated:
          already++;
        case _ItemResult.validationRequired:
          validationRequired++;
        case _ItemResult.failed:
          failed++;
      }
    }
    for (final item in vitamins) {
      final result = await _migrateVitamin(item, timeZone, startedAtUtc);
      switch (result) {
        case _ItemResult.migrated:
          migrated++;
        case _ItemResult.alreadyMigrated:
          already++;
        case _ItemResult.validationRequired:
          validationRequired++;
        case _ItemResult.failed:
          failed++;
      }
    }
    return UnifiedTreatmentMigrationResult(
      detected: medications.length + vitamins.length,
      migrated: migrated,
      alreadyMigrated: already,
      validationRequired: validationRequired,
      failed: failed,
      duration: stopwatch.elapsed,
    );
  }

  Future<_ItemResult> _migrateMedication(
    MedicationRecord item,
    String? timeZone,
    DateTime now,
  ) async {
    final logs =
        await (database.select(database.medicationLogRecords)..where(
              (row) =>
                  row.userId.equals(item.userId) &
                  row.medicationId.equals(item.id),
            ))
            .get();
    return _migrate(
      userId: item.userId,
      source: UnifiedTreatmentLegacySource.medication,
      legacyId: item.id,
      name: item.name,
      hour: item.scheduleHour,
      minute: item.scheduleMinute,
      dosage: item.dosage,
      notes: item.notes,
      createdAt: item.createdAt,
      deletedAt: item.deletedAt,
      logs: [
        for (final log in logs) _LegacyLog(log.id, log.logDate, log.status),
      ],
      timeZone: timeZone,
      now: now,
    );
  }

  Future<_ItemResult> _migrateVitamin(
    VitaminRecord item,
    String? timeZone,
    DateTime now,
  ) async {
    final logs =
        await (database.select(database.vitaminLogRecords)..where(
              (row) =>
                  row.userId.equals(item.userId) &
                  row.vitaminId.equals(item.id),
            ))
            .get();
    return _migrate(
      userId: item.userId,
      source: UnifiedTreatmentLegacySource.vitamin,
      legacyId: item.id,
      name: item.name,
      hour: item.scheduleHour,
      minute: item.scheduleMinute,
      createdAt: item.createdAt,
      deletedAt: item.deletedAt,
      logs: [
        for (final log in logs) _LegacyLog(log.id, log.logDate, log.status),
      ],
      timeZone: timeZone,
      now: now,
    );
  }

  Future<_ItemResult> _migrate({
    required String userId,
    required UnifiedTreatmentLegacySource source,
    required String legacyId,
    required String name,
    required int hour,
    required int minute,
    required DateTime createdAt,
    required DateTime? deletedAt,
    required List<_LegacyLog> logs,
    required String? timeZone,
    required DateTime now,
    String? dosage,
    String? notes,
  }) async {
    final mappingId = _id(
      userId,
      source,
      legacyId,
      UnifiedTreatmentTargetEntity.mapping,
    );
    final existing =
        await (database.select(database.unifiedTreatmentLegacyMappings)..where(
              (row) => row.userId.equals(userId) & row.id.equals(mappingId),
            ))
            .getSingleOrNull();
    if (existing?.status == UnifiedTreatmentMigrationStatus.completed.name) {
      return _ItemResult.alreadyMigrated;
    }
    final routineId = _id(
      userId,
      source,
      legacyId,
      UnifiedTreatmentTargetEntity.routine,
    );
    final planId = _id(
      userId,
      source,
      legacyId,
      UnifiedTreatmentTargetEntity.plan,
    );
    final scheduleId = _id(
      userId,
      source,
      legacyId,
      UnifiedTreatmentTargetEntity.schedule,
    );
    if (timeZone == null) {
      await _writeMapping(
        mappingId: mappingId,
        userId: userId,
        source: source,
        legacyId: legacyId,
        routineId: routineId,
        planId: planId,
        scheduleId: scheduleId,
        status: UnifiedTreatmentMigrationStatus.validationRequired,
        now: now,
        validationSummary: const {'timezone': 'required'},
      );
      return _ItemResult.validationRequired;
    }
    try {
      await database.transaction(() async {
        final anchor = _anchor(createdAt, logs);
        await database
            .into(database.smartRoutineRecords)
            .insert(
              SmartRoutineRecordsCompanion.insert(
                id: routineId,
                userId: userId,
                category: source.name,
                displayName: name,
                status: deletedAt == null ? 'active' : 'archived',
                source: source == UnifiedTreatmentLegacySource.medication
                    ? 'legacyMedication'
                    : 'legacyVitamin',
                personalNotes: Value(notes),
                createdAt: createdAt,
                updatedAt: now,
                deletedAt: Value(deletedAt),
                syncStatus: 'pendingCreate',
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await database
            .into(database.routinePlanRecords)
            .insert(
              RoutinePlanRecordsCompanion.insert(
                id: planId,
                userId: userId,
                routineId: routineId,
                revision: 1,
                category: Value(source.name),
                mode: 'scheduled',
                durationType: 'unknown',
                effectiveFrom: _date(anchor),
                doseOriginalText: Value(dosage),
                activatedAt: Value(createdAt.toUtc()),
                provenanceOrigin: const Value('migratedLegacy'),
                validationStatus: const Value('estimated'),
                temporalPrecision: const Value('estimatedFromLegacyDate'),
                createdAt: createdAt,
                updatedAt: now,
                syncStatus: 'pendingCreate',
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await database
            .into(database.routineScheduleRecords)
            .insert(
              RoutineScheduleRecordsCompanion.insert(
                id: scheduleId,
                userId: userId,
                routineId: routineId,
                planId: planId,
                ruleJson: jsonEncode({
                  'schemaVersion': 1,
                  'type': 'dailyAtTimes',
                  'times': [
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  ],
                }),
                timeZone: timeZone,
                reminderPreference: 'enabled',
                earlyToleranceSeconds: 0,
                onTimeToleranceSeconds: 1800,
                lateToleranceSeconds: 43200,
                isEnabled: true,
                displayOrder: 0,
                createdAt: createdAt,
                updatedAt: now,
                syncStatus: 'pendingCreate',
              ),
              mode: InsertMode.insertOrIgnore,
            );
        for (final log in logs) {
          await _migrateLog(
            userId: userId,
            source: source,
            legacyEntityId: legacyId,
            routineId: routineId,
            planId: planId,
            scheduleId: scheduleId,
            hour: hour,
            minute: minute,
            timeZone: timeZone,
            log: log,
            now: now,
          );
        }
        await _writeMapping(
          mappingId: mappingId,
          userId: userId,
          source: source,
          legacyId: legacyId,
          routineId: routineId,
          planId: planId,
          scheduleId: scheduleId,
          status: UnifiedTreatmentMigrationStatus.completed,
          now: now,
          completedAt: now,
          timeZone: timeZone,
          validationSummary: {
            'logs': logs.length,
            'taken': logs.where((value) => value.status == 'taken').length,
            'skipped': logs.where((value) => value.status == 'skipped').length,
          },
        );
      });
      return _ItemResult.migrated;
    } on Object {
      await _writeMapping(
        mappingId: mappingId,
        userId: userId,
        source: source,
        legacyId: legacyId,
        routineId: routineId,
        planId: planId,
        scheduleId: scheduleId,
        status: UnifiedTreatmentMigrationStatus.failed,
        now: now,
        failureCode: 'entity_transaction_failed',
        timeZone: timeZone,
        validationSummary: const {'result': 'failed'},
      );
      return _ItemResult.failed;
    }
  }

  Future<void> _migrateLog({
    required String userId,
    required UnifiedTreatmentLegacySource source,
    required String legacyEntityId,
    required String routineId,
    required String planId,
    required String scheduleId,
    required int hour,
    required int minute,
    required String timeZone,
    required _LegacyLog log,
    required DateTime now,
  }) async {
    final target = tz.TZDateTime(
      tz.getLocation(timeZone),
      log.date.year,
      log.date.month,
      log.date.day,
      hour,
      minute,
    ).toUtc();
    final occurrenceId = _id(
      userId,
      source,
      log.id,
      UnifiedTreatmentTargetEntity.occurrence,
    );
    final eventId = _id(
      userId,
      source,
      log.id,
      UnifiedTreatmentTargetEntity.adherenceEvent,
    );
    final mappingId = _id(
      userId,
      source,
      log.id,
      UnifiedTreatmentTargetEntity.logMapping,
    );
    await database
        .into(database.routineOccurrenceRecords)
        .insert(
          RoutineOccurrenceRecordsCompanion.insert(
            id: occurrenceId,
            userId: userId,
            routineId: routineId,
            planId: planId,
            scheduleId: Value(scheduleId),
            origin: 'migrated',
            status: 'expected',
            originalClinicalDate: _date(log.date),
            originalLocalHour: hour,
            originalLocalMinute: minute,
            originalTimeZone: timeZone,
            expectationKind: 'recurringExpectation',
            sequence: 0,
            originalScheduledFor: target,
            originalWindowStartsAt: target,
            originalOnTimeEndsAt: target.add(const Duration(minutes: 30)),
            originalWindowEndsAt: target.add(const Duration(hours: 12)),
            scheduledFor: target,
            windowStartsAt: target,
            onTimeEndsAt: target.add(const Duration(minutes: 30)),
            windowEndsAt: target.add(const Duration(hours: 12)),
            createdAt: now,
            updatedAt: now,
            syncStatus: 'pendingCreate',
          ),
          mode: InsertMode.insertOrIgnore,
        );
    if (log.status == 'taken' || log.status == 'skipped') {
      await database
          .into(database.routineAdherenceEventRecords)
          .insert(
            RoutineAdherenceEventRecordsCompanion.insert(
              id: eventId,
              userId: userId,
              occurrenceId: occurrenceId,
              routineId: routineId,
              planId: planId,
              scheduleId: Value(scheduleId),
              type: log.status,
              actor: 'imported',
              occurredAtUtc: target,
              recordedAtUtc: now,
              createdAt: now,
              updatedAt: now,
              syncStatus: 'pendingCreate',
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await database
        .into(database.unifiedTreatmentLegacyLogMappings)
        .insert(
          UnifiedTreatmentLegacyLogMappingsCompanion.insert(
            id: mappingId,
            userId: userId,
            sourceType: source.name,
            legacyLogId: log.id,
            legacyEntityId: legacyEntityId,
            occurrenceId: occurrenceId,
            adherenceEventId: Value(
              log.status == 'taken' || log.status == 'skipped' ? eventId : null,
            ),
            temporalPrecision: 'estimatedFromLegacyDate',
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<String?> _trustedTimeZone(String userId) async {
    final rows =
        await (database.select(database.privacyConsentRecords)
              ..where((row) => row.userId.equals(userId))
              ..orderBy([(row) => OrderingTerm.desc(row.acceptedAt)]))
            .get();
    for (final row in rows) {
      try {
        tz.getLocation(row.timezone);
        return row.timezone;
      } on Object {
        continue;
      }
    }
    return null;
  }

  Future<void> _writeMapping({
    required String mappingId,
    required String userId,
    required UnifiedTreatmentLegacySource source,
    required String legacyId,
    required String routineId,
    required String planId,
    required String scheduleId,
    required UnifiedTreatmentMigrationStatus status,
    required DateTime now,
    required Map<String, Object?> validationSummary,
    DateTime? completedAt,
    String? timeZone,
    String? failureCode,
  }) => database
      .into(database.unifiedTreatmentLegacyMappings)
      .insertOnConflictUpdate(
        UnifiedTreatmentLegacyMappingsCompanion.insert(
          id: mappingId,
          userId: userId,
          sourceType: source.name,
          legacyEntityId: legacyId,
          targetRoutineId: routineId,
          targetPlanId: planId,
          targetScheduleId: scheduleId,
          migrationSchemaVersion: migrationSchemaVersion,
          status: status.name,
          startedAtUtc: now,
          completedAtUtc: Value(completedAt),
          failureCode: Value(failureCode),
          validationSummary: jsonEncode(validationSummary),
          timeZone: Value(timeZone),
          temporalPrecision: timeZone == null
              ? 'unknown'
              : 'inferredFromProfile',
          createdAt: now,
          updatedAt: now,
        ),
      );

  String _id(
    String userId,
    UnifiedTreatmentLegacySource source,
    String legacyId,
    UnifiedTreatmentTargetEntity target,
  ) => identity.generate(
    userId: userId,
    source: source,
    legacyId: legacyId,
    target: target,
  );

  DateTime _anchor(DateTime createdAt, List<_LegacyLog> logs) {
    if (logs.isEmpty) return createdAt;
    final dates = logs.map((value) => value.date).toList()..sort();
    return dates.first;
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

enum _ItemResult { migrated, alreadyMigrated, validationRequired, failed }

final class _LegacyLog {
  const _LegacyLog(this.id, this.date, this.status);
  final String id;
  final DateTime date;
  final String status;
}
