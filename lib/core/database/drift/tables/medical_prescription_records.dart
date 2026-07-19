import 'package:drift/drift.dart';

@TableIndex(
  name: 'medical_prescriptions_user_date_idx',
  columns: {#userId, #deletedAt, #prescribedAt},
)
@TableIndex(
  name: 'medical_prescriptions_user_status_idx',
  columns: {#userId, #status},
)
@TableIndex(
  name: 'medical_prescriptions_user_document_idx',
  columns: {#userId, #sourceDocumentId},
)
@TableIndex(
  name: 'medical_prescriptions_user_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class MedicalPrescriptionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get professionalName => text().nullable()();
  TextColumn get professionalSpecialty => text().nullable()();
  TextColumn get professionalRegistration => text().nullable()();
  DateTimeColumn get prescribedAt => dateTime()();
  DateTimeColumn get validUntil => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get sourceDocumentId => text().nullable()();
  TextColumn get status => text()();
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
  name: 'medical_prescription_items_parent_idx',
  columns: {#userId, #prescriptionId, #deletedAt},
)
@TableIndex(
  name: 'medical_prescription_items_type_idx',
  columns: {#userId, #itemType},
)
@TableIndex(
  name: 'medical_prescription_items_links_idx',
  columns: {#userId, #linkedMedicationId, #linkedVitaminId},
)
@TableIndex(
  name: 'medical_prescription_items_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class MedicalPrescriptionItemRecords extends Table {
  TextColumn get id => text()();
  TextColumn get prescriptionId => text()();
  TextColumn get userId => text()();
  TextColumn get itemType => text()();
  TextColumn get name => text()();
  RealColumn get dosageValue => real().nullable()();
  TextColumn get dosageUnit => text().nullable()();
  TextColumn get route => text().nullable()();
  TextColumn get frequencyType => text().nullable()();
  IntColumn get frequencyValue => integer().nullable()();
  TextColumn get frequencyUnit => text().nullable()();
  TextColumn get scheduleTimesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get daysOfWeekJson => text().withDefault(const Constant('[]'))();
  IntColumn get intervalDays => integer().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get durationValue => integer().nullable()();
  TextColumn get durationUnit => text().nullable()();
  TextColumn get instructions => text().nullable()();
  BoolColumn get asNeeded => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  RealColumn get confidence => real().nullable()();
  TextColumn get fieldConfidencesJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get provenanceJson => text().withDefault(const Constant('{}'))();
  TextColumn get reviewStatus => text()();
  TextColumn get linkedMedicationId => text().nullable()();
  TextColumn get linkedVitaminId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();
  TextColumn get previousSyncStatus => text().nullable()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, prescriptionId, id},
  ];
}
