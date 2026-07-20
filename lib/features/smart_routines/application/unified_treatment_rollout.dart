import 'package:drift/drift.dart';

import '../../../core/database/drift/app_database.dart';

enum UnifiedTreatmentFlag {
  migrationEnabled('unified_treatment_migration_enabled'),
  cutoverEnabled('unified_treatment_cutover_enabled'),
  readNewEnabled('unified_treatment_read_new_enabled'),
  writeNewEnabled('unified_treatment_write_new_enabled'),
  remoteSyncEnabled('unified_treatment_remote_sync_enabled');

  const UnifiedTreatmentFlag(this.key);
  final String key;
}

enum UnifiedTreatmentCutoverPhase {
  legacyRead,
  detected,
  migrating,
  validationRequired,
  validated,
  readNew,
  writeNew,
  recoveryRequired,
}

final class UnifiedTreatmentRolloutRepository {
  const UnifiedTreatmentRolloutRepository(this.database);
  final AppDatabase database;

  Future<bool> isEnabled(
    UnifiedTreatmentFlag flag,
    DateTime evaluatedAtUtc,
  ) async {
    final row = await (database.select(
      database.unifiedTreatmentRolloutFlags,
    )..where((value) => value.key.equals(flag.key))).getSingleOrNull();
    return row != null &&
        row.enabled &&
        (row.expiresAt == null || row.expiresAt!.isAfter(evaluatedAtUtc));
  }

  Future<void> persist({
    required UnifiedTreatmentFlag flag,
    required bool enabled,
    required DateTime updatedAtUtc,
    String source = 'localAdmin',
    DateTime? expiresAtUtc,
  }) => database
      .into(database.unifiedTreatmentRolloutFlags)
      .insertOnConflictUpdate(
        UnifiedTreatmentRolloutFlagsCompanion.insert(
          key: flag.key,
          enabled: enabled,
          source: source,
          updatedAt: updatedAtUtc,
          expiresAt: Value(expiresAtUtc),
        ),
      );

  Future<UnifiedTreatmentCutoverPhase> stateFor(String userId) async {
    final row = await (database.select(
      database.unifiedTreatmentCutoverStates,
    )..where((value) => value.userId.equals(userId))).getSingleOrNull();
    return UnifiedTreatmentCutoverPhase.values.firstWhere(
      (value) => value.name == row?.state,
      orElse: () => UnifiedTreatmentCutoverPhase.legacyRead,
    );
  }
}
