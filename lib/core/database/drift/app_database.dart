import 'package:drift/drift.dart';

import 'daos/water_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/weight_dao.dart';
import 'daos/meal_dao.dart';
import 'daos/appointment_dao.dart';
import 'daos/exam_dao.dart';
import 'daos/vitamin_dao.dart';
import 'daos/vitamin_log_dao.dart';
import 'daos/medication_dao.dart';
import 'daos/medication_log_dao.dart';
import 'daos/privacy_consent_dao.dart';
import 'daos/document_intelligence_dao.dart';
import 'daos/bioimpedance_dao.dart';
import 'daos/medical_exam_dao.dart';
import 'daos/medical_prescription_dao.dart';
import 'daos/onboarding_state_dao.dart';
import 'daos/smart_routine_dao.dart';
import 'database_connection.dart';
import 'tables/local_migrations.dart';
import 'tables/sync_cursors.dart';
import 'tables/sync_devices.dart';
import 'tables/water_records.dart';
import 'tables/water_cutovers.dart';
import 'tables/settings_records.dart';
import 'tables/settings_cutovers.dart';
import 'tables/profile_records.dart';
import 'tables/profile_cutovers.dart';
import 'tables/weight_records.dart';
import 'tables/weight_cutovers.dart';
import 'tables/meal_records.dart';
import 'tables/meal_cutovers.dart';
import 'tables/appointment_records.dart';
import 'tables/appointment_cutovers.dart';
import 'tables/exam_records.dart';
import 'tables/exam_cutovers.dart';
import 'tables/vitamin_records.dart';
import 'tables/vitamin_log_records.dart';
import 'tables/vitamin_cutovers.dart';
import 'tables/medication_records.dart';
import 'tables/medication_log_records.dart';
import 'tables/medication_cutovers.dart';
import 'tables/privacy_consent_records.dart';
import 'tables/document_intelligence_records.dart';
import 'tables/bioimpedance_records.dart';
import 'tables/medical_exams.dart';
import 'tables/medical_exam_results.dart';
import 'tables/medical_prescription_records.dart';
import 'tables/onboarding_state_records.dart';
import 'tables/smart_routine_records.dart';
import 'tables/macro2_records.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WaterRecords,
    SyncCursors,
    SyncDevices,
    LocalMigrations,
    WaterCutovers,
    SettingsRecords,
    SettingsCutovers,
    ProfileRecords,
    ProfileCutovers,
    WeightRecords,
    WeightCutovers,
    MealRecords,
    MealCutovers,
    AppointmentRecords,
    AppointmentCutovers,
    ExamRecords,
    ExamCutovers,
    VitaminRecords,
    VitaminLogRecords,
    VitaminCutovers,
    MedicationRecords,
    MedicationLogRecords,
    MedicationCutovers,
    PrivacyConsentRecords,
    DocumentInputRecords,
    DocumentProcessingRecords,
    ExtractedFieldRecords,
    BioimpedanceRecords,
    MedicalExams,
    MedicalExamResults,
    MedicalPrescriptionRecords,
    MedicalPrescriptionItemRecords,
    SmartRoutineRecords,
    RoutinePlanRecords,
    RoutineScheduleRecords,
    RoutinePauseRecords,
    RoutineOccurrenceRecords,
    RoutineAdherenceEventRecords,
    UnifiedTreatmentLegacyMappings,
    UnifiedTreatmentLegacyLogMappings,
    UnifiedTreatmentRolloutFlags,
    UnifiedTreatmentCutoverStates,
    PrescriptionVersionRecords,
    PrescriptionReviewRecords,
    TreatmentProposalRecords,
    PrescriptionRoutineLinkRecords,
    NotificationManifestRecords,
    NotificationActionInboxRecords,
    OnboardingStateRecords,
  ],
  daos: [
    WaterDao,
    SettingsDao,
    ProfileDao,
    WeightDao,
    MealDao,
    AppointmentDao,
    ExamDao,
    VitaminDao,
    VitaminLogDao,
    MedicationDao,
    MedicationLogDao,
    PrivacyConsentDao,
    DocumentIntelligenceDao,
    BioimpedanceDao,
    MedicalExamDao,
    MedicalPrescriptionDao,
    OnboardingStateDao,
    SmartRoutineDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openHelpBariDatabase());

  @override
  int get schemaVersion => 22;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(waterCutovers);
      if (from < 3) {
        await migrator.createTable(settingsRecords);
        await migrator.createTable(settingsCutovers);
      }
      if (from < 4) {
        await migrator.createTable(profileRecords);
        await migrator.createTable(profileCutovers);
      }
      if (from < 5) {
        await migrator.addColumn(
          profileRecords,
          profileRecords.photoStoragePath,
        );
      }
      if (from < 6) {
        await migrator.createTable(weightRecords);
        await migrator.createTable(weightCutovers);
      }
      if (from < 7) {
        await migrator.createTable(mealRecords);
        await migrator.createTable(mealCutovers);
      }
      if (from < 8) {
        await migrator.createTable(appointmentRecords);
        await migrator.createTable(appointmentCutovers);
      }
      if (from < 9) {
        await migrator.createTable(examRecords);
        await migrator.createTable(examCutovers);
      }
      if (from < 10) {
        await migrator.createTable(vitaminRecords);
        await migrator.createTable(vitaminLogRecords);
        await migrator.createTable(vitaminCutovers);
      }
      if (from < 11) {
        await migrator.createTable(medicationRecords);
        await migrator.createTable(medicationLogRecords);
        await migrator.createTable(medicationCutovers);
      }
      if (from < 12) {
        await migrator.createTable(privacyConsentRecords);
      }
      if (from < 13) {
        await migrator.createTable(documentInputRecords);
        await migrator.createTable(documentProcessingRecords);
        await migrator.createTable(extractedFieldRecords);
      }
      if (from < 14) {
        await migrator.createTable(bioimpedanceRecords);
      }
      if (from < 15) {
        await migrator.createTable(medicalExams);
        await migrator.createTable(medicalExamResults);
      }
      if (from < 16) {
        await migrator.addColumn(
          medicalExams,
          medicalExams.legacyAttachmentPath,
        );
      }
      if (from < 17) {
        await migrator.createTable(medicalPrescriptionRecords);
        await migrator.createTable(medicalPrescriptionItemRecords);
      }
      if (from < 18) {
        await migrator.createTable(smartRoutineRecords);
        await migrator.createTable(routinePlanRecords);
        await migrator.createTable(routineScheduleRecords);
        await migrator.createTable(routinePauseRecords);
        await migrator.createTable(routineOccurrenceRecords);
        await migrator.createTable(routineAdherenceEventRecords);
      }
      if (from < 19) {
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.category,
        );
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.provenanceOrigin,
        );
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.validationStatus,
        );
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.provenancePrescriptionId,
        );
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.provenancePrescriptionItemId,
        );
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.provenanceDocumentId,
        );
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.provenanceProfessionalReference,
        );
        await migrator.addColumn(
          routinePlanRecords,
          routinePlanRecords.temporalPrecision,
        );
        await customStatement(
          "UPDATE routine_plan_records SET duration_type = 'bounded' "
          "WHERE duration_type = 'fixed'",
        );
        await migrator.createTable(unifiedTreatmentLegacyMappings);
        await migrator.createTable(unifiedTreatmentLegacyLogMappings);
        await migrator.createTable(unifiedTreatmentRolloutFlags);
        await migrator.createTable(unifiedTreatmentCutoverStates);
      }
      if (from < 20) {
        await migrator.createTable(prescriptionVersionRecords);
        await migrator.createTable(prescriptionReviewRecords);
        await migrator.createTable(treatmentProposalRecords);
        await migrator.createTable(prescriptionRoutineLinkRecords);
        await migrator.createTable(notificationManifestRecords);
        await migrator.createTable(notificationActionInboxRecords);
      }
      if (from < 21) {
        await migrator.createTable(onboardingStateRecords);
        await migrator.addColumn(
          settingsRecords,
          settingsRecords.treatmentTrackingEnabled,
        );
        await migrator.addColumn(
          settingsRecords,
          settingsRecords.waterTrackingEnabled,
        );
        await migrator.addColumn(
          settingsRecords,
          settingsRecords.weightTrackingEnabled,
        );
      }
      if (from < 22) {
        await migrator.addColumn(
          settingsRecords,
          settingsRecords.notificationPreferencesJson,
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.versionNow >= 20) {
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS prescription_versions_immutable
          BEFORE UPDATE ON prescription_version_records
          WHEN OLD.status IN ('confirmed', 'archived') AND NOT (
            OLD.status = 'confirmed' AND NEW.status = 'archived' AND
            NEW.snapshot_json = OLD.snapshot_json AND
            NEW.prescription_id = OLD.prescription_id AND
            NEW.revision = OLD.revision AND
            NEW.source_processing_id IS OLD.source_processing_id AND
            NEW.submitted_at IS OLD.submitted_at AND
            NEW.confirmed_at IS OLD.confirmed_at AND
            NEW.deleted_at IS OLD.deleted_at AND
            NEW.created_at = OLD.created_at
          ) AND NOT (
            NEW.status = OLD.status AND
            NEW.snapshot_json = OLD.snapshot_json AND
            NEW.prescription_id = OLD.prescription_id AND
            NEW.revision = OLD.revision AND
            NEW.source_processing_id IS OLD.source_processing_id AND
            NEW.submitted_at IS OLD.submitted_at AND
            NEW.confirmed_at IS OLD.confirmed_at AND
            NEW.deleted_at IS OLD.deleted_at AND
            NEW.created_at = OLD.created_at
          )
          BEGIN SELECT RAISE(ABORT, 'immutable prescription version'); END
        ''');
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS prescription_reviews_append_only
          BEFORE UPDATE ON prescription_review_records
          WHEN NEW.prescription_id != OLD.prescription_id OR
            NEW.version_id != OLD.version_id OR
            NEW.decision != OLD.decision OR NEW.actor != OLD.actor OR
            NEW.field_decisions_json != OLD.field_decisions_json OR
            NEW.note IS NOT OLD.note OR NEW.created_at != OLD.created_at
          BEGIN SELECT RAISE(ABORT, 'append-only prescription review'); END
        ''');
      }
      if (details.versionNow >= 19) {
        await batch((batch) {
          final now = DateTime.now().toUtc();
          for (final entry in const <String, bool>{
            'unified_treatment_migration_enabled': true,
            'unified_treatment_cutover_enabled': true,
            'unified_treatment_read_new_enabled': true,
            'unified_treatment_write_new_enabled': true,
            'unified_treatment_remote_sync_enabled': true,
          }.entries) {
            batch.insert(
              unifiedTreatmentRolloutFlags,
              UnifiedTreatmentRolloutFlagsCompanion.insert(
                key: entry.key,
                enabled: entry.value,
                source: 'schemaDefault',
                updatedAt: now,
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        });
        await (update(unifiedTreatmentRolloutFlags)..where(
              (row) =>
                  row.key.equals('unified_treatment_remote_sync_enabled') &
                  row.enabled.equals(false) &
                  row.source.equals('schemaDefault'),
            ))
            .write(
              UnifiedTreatmentRolloutFlagsCompanion(
                enabled: const Value(true),
                source: const Value('schemaDefaultV2'),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
      }
    },
  );
}
