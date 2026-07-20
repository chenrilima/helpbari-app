import 'package:drift/drift.dart';

import '../../../core/database/drift/app_database.dart';
import 'unified_treatment_migrator.dart';
import 'unified_treatment_rollout.dart';

final class UnifiedTreatmentValidationResult {
  const UnifiedTreatmentValidationResult({
    required this.isValid,
    required this.legacyEntities,
    required this.completedMappings,
    required this.legacyLogs,
    required this.logMappings,
    required this.failureCode,
  });

  final bool isValid;
  final int legacyEntities;
  final int completedMappings;
  final int legacyLogs;
  final int logMappings;
  final String? failureCode;
}

final class UnifiedTreatmentCutoverService {
  const UnifiedTreatmentCutoverService({
    required this.database,
    required this.rollout,
  });

  final AppDatabase database;
  final UnifiedTreatmentRolloutRepository rollout;

  Future<UnifiedTreatmentValidationResult> validate(String userId) async {
    final medications = await (database.select(
      database.medicationRecords,
    )..where((row) => row.userId.equals(userId))).get();
    final vitamins = await (database.select(
      database.vitaminRecords,
    )..where((row) => row.userId.equals(userId))).get();
    final medicationLogs = await (database.select(
      database.medicationLogRecords,
    )..where((row) => row.userId.equals(userId))).get();
    final vitaminLogs = await (database.select(
      database.vitaminLogRecords,
    )..where((row) => row.userId.equals(userId))).get();
    final mappings = await (database.select(
      database.unifiedTreatmentLegacyMappings,
    )..where((row) => row.userId.equals(userId))).get();
    final logMappings = await (database.select(
      database.unifiedTreatmentLegacyLogMappings,
    )..where((row) => row.userId.equals(userId))).get();
    final legacyEntities = medications.length + vitamins.length;
    final legacyLogs = medicationLogs.length + vitaminLogs.length;
    final completed = mappings
        .where(
          (row) => row.status == UnifiedTreatmentMigrationStatus.completed.name,
        )
        .toList();
    String? failure;
    if (completed.length != legacyEntities) {
      failure = 'entity_count_mismatch';
    } else if (logMappings.length != legacyLogs) {
      failure = 'log_count_mismatch';
    } else if (completed.map((row) => row.targetRoutineId).toSet().length !=
        completed.length) {
      failure = 'duplicate_target';
    } else {
      for (final mapping in completed) {
        final routine =
            await (database.select(database.smartRoutineRecords)..where(
                  (row) =>
                      row.userId.equals(userId) &
                      row.id.equals(mapping.targetRoutineId),
                ))
                .getSingleOrNull();
        final plan =
            await (database.select(database.routinePlanRecords)..where(
                  (row) =>
                      row.userId.equals(userId) &
                      row.id.equals(mapping.targetPlanId),
                ))
                .getSingleOrNull();
        final schedule =
            await (database.select(database.routineScheduleRecords)..where(
                  (row) =>
                      row.userId.equals(userId) &
                      row.id.equals(mapping.targetScheduleId),
                ))
                .getSingleOrNull();
        if (routine == null || plan == null || schedule == null) {
          failure = 'target_missing';
          break;
        }
        if (routine.category != plan.category ||
            schedule.routineId != routine.id ||
            schedule.planId != plan.id) {
          failure = 'target_relationship_mismatch';
          break;
        }
      }
    }
    return UnifiedTreatmentValidationResult(
      isValid: failure == null,
      legacyEntities: legacyEntities,
      completedMappings: completed.length,
      legacyLogs: legacyLogs,
      logMappings: logMappings.length,
      failureCode: failure,
    );
  }

  Future<bool> attempt({
    required String userId,
    required DateTime evaluatedAtUtc,
  }) async {
    if (!await rollout.isEnabled(
          UnifiedTreatmentFlag.cutoverEnabled,
          evaluatedAtUtc,
        ) ||
        !await rollout.isEnabled(
          UnifiedTreatmentFlag.readNewEnabled,
          evaluatedAtUtc,
        )) {
      return false;
    }
    final validation = await validate(userId);
    if (!validation.isValid) {
      await _persistState(
        userId,
        UnifiedTreatmentCutoverPhase.validationRequired,
        evaluatedAtUtc,
        recoveryCode: validation.failureCode,
      );
      return false;
    }
    await _persistState(
      userId,
      UnifiedTreatmentCutoverPhase.readNew,
      evaluatedAtUtc,
      validatedAt: evaluatedAtUtc,
      readNewAt: evaluatedAtUtc,
    );
    return true;
  }

  Future<bool> enableNewWrites({
    required String userId,
    required DateTime evaluatedAtUtc,
  }) async {
    if (await rollout.stateFor(userId) !=
            UnifiedTreatmentCutoverPhase.readNew ||
        !await rollout.isEnabled(
          UnifiedTreatmentFlag.writeNewEnabled,
          evaluatedAtUtc,
        )) {
      return false;
    }
    await _persistState(
      userId,
      UnifiedTreatmentCutoverPhase.writeNew,
      evaluatedAtUtc,
      writeNewAt: evaluatedAtUtc,
    );
    return true;
  }

  Future<bool> rollbackReadBeforeNewWrites({
    required String userId,
    required DateTime evaluatedAtUtc,
  }) async {
    final mappings =
        await (database.select(database.unifiedTreatmentLegacyMappings)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.hasNewClinicalWrites.equals(true),
            ))
            .get();
    if (mappings.isNotEmpty ||
        await rollout.stateFor(userId) ==
            UnifiedTreatmentCutoverPhase.writeNew) {
      return false;
    }
    await _persistState(
      userId,
      UnifiedTreatmentCutoverPhase.legacyRead,
      evaluatedAtUtc,
    );
    return true;
  }

  Future<void> _persistState(
    String userId,
    UnifiedTreatmentCutoverPhase state,
    DateTime updatedAt, {
    DateTime? validatedAt,
    DateTime? readNewAt,
    DateTime? writeNewAt,
    String? recoveryCode,
  }) => database
      .into(database.unifiedTreatmentCutoverStates)
      .insertOnConflictUpdate(
        UnifiedTreatmentCutoverStatesCompanion.insert(
          userId: userId,
          state: state.name,
          migrationSchemaVersion:
              UnifiedTreatmentMigrator.migrationSchemaVersion,
          validatedAtUtc: Value(validatedAt),
          readNewAtUtc: Value(readNewAt),
          writeNewAtUtc: Value(writeNewAt),
          recoveryCode: Value(recoveryCode),
          updatedAt: updatedAt,
        ),
      );
}
