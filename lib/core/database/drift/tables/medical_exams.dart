import 'package:drift/drift.dart';

@TableIndex(
  name: 'medical_exams_user_deleted_performed_idx',
  columns: {#userId, #deletedAt, #performedAt},
)
@TableIndex(
  name: 'medical_exams_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
@TableIndex(
  name: 'medical_exams_user_source_document_idx',
  columns: {#userId, #sourceDocumentId},
)
class MedicalExams extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get performedAt => dateTime()();
  DateTimeColumn get collectedAt => dateTime().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get laboratoryName => text().nullable()();
  TextColumn get professionalName => text().nullable()();
  TextColumn get requestProfessionalName => text().nullable()();
  TextColumn get documentNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text()();
  TextColumn get sourceDocumentId => text().nullable()();
  TextColumn get legacyAttachmentPath => text().nullable()();
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
