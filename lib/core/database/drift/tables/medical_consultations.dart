import 'package:drift/drift.dart';

@TableIndex(
  name: 'medical_consultations_user_deleted_at_idx',
  columns: {#userId, #deletedAt, #consultationAt},
)
@TableIndex(
  name: 'medical_consultations_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
@TableIndex(
  name: 'medical_consultations_user_appointment_idx',
  columns: {#userId, #appointmentId},
)
@TableIndex(
  name: 'medical_consultations_user_source_document_idx',
  columns: {#userId, #sourceDocumentId},
)
class MedicalConsultations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get consultationAt => dateTime()();
  TextColumn get title => text().nullable()();
  TextColumn get specialty => text().nullable()();
  TextColumn get consultationType =>
      text().withDefault(const Constant('unknown'))();
  TextColumn get professionalName => text().nullable()();
  TextColumn get professionalRegistration => text().nullable()();
  TextColumn get clinicName => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get appointmentId => text().nullable()();
  TextColumn get source => text()();
  TextColumn get sourceDocumentId => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get symptoms => text().nullable()();
  TextColumn get patientNotes => text().nullable()();
  TextColumn get professionalGuidance => text().nullable()();
  TextColumn get dietaryGuidance => text().nullable()();
  TextColumn get physicalActivityGuidance => text().nullable()();
  TextColumn get supplementGuidance => text().nullable()();
  TextColumn get medicationGuidance => text().nullable()();
  TextColumn get requestedExamsNotes => text().nullable()();
  TextColumn get followUpNotes => text().nullable()();
  DateTimeColumn get nextAppointmentAt => dateTime().nullable()();
  TextColumn get generalNotes => text().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get bmi => real().nullable()();
  IntColumn get bloodPressureSystolic => integer().nullable()();
  IntColumn get bloodPressureDiastolic => integer().nullable()();
  IntColumn get heartRateBpm => integer().nullable()();
  RealColumn get waistCircumferenceCm => real().nullable()();
  TextColumn get additionalFieldsJson => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();
  TextColumn get previousSyncStatus => text().nullable()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, id};
}

@TableIndex(
  name: 'medical_consultation_exams_lookup_idx',
  columns: {#userId, #medicalConsultationId, #medicalExamId},
)
class MedicalConsultationExams extends Table {
  TextColumn get userId => text()();
  TextColumn get medicalConsultationId => text()();
  TextColumn get medicalExamId => text()();

  @override
  Set<Column<Object>> get primaryKey => {
    userId,
    medicalConsultationId,
    medicalExamId,
  };
}

@TableIndex(
  name: 'medical_consultation_body_lookup_idx',
  columns: {#userId, #medicalConsultationId, #bioimpedanceRecordId},
)
class MedicalConsultationBodyCompositions extends Table {
  TextColumn get userId => text()();
  TextColumn get medicalConsultationId => text()();
  TextColumn get bioimpedanceRecordId => text()();

  @override
  Set<Column<Object>> get primaryKey => {
    userId,
    medicalConsultationId,
    bioimpedanceRecordId,
  };
}
