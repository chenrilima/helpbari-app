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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openHelpBariDatabase());

  @override
  int get schemaVersion => 17;

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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
