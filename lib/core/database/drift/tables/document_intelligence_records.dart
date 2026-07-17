import 'package:drift/drift.dart';

@TableIndex(
  name: 'document_input_user_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class DocumentInputRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get sourceType => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remotePath => text().nullable()();
  TextColumn get mimeType => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get checksum => text().nullable()();
  DateTimeColumn get capturedAt => dateTime()();
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
  name: 'document_processing_user_document_idx',
  columns: {#userId, #documentId, #updatedAt},
)
class DocumentProcessingRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get documentId => text()();
  TextColumn get status => text()();
  TextColumn get detectedType => text()();
  TextColumn get rawText => text().nullable()();
  TextColumn get engine => text()();
  TextColumn get engineVersion => text().nullable()();
  RealColumn get generalConfidence => real()();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();
  @override
  Set<Column<Object>> get primaryKey => {userId, id};
}

@TableIndex(
  name: 'extracted_field_user_processing_idx',
  columns: {#userId, #processingId, #updatedAt},
)
class ExtractedFieldRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get processingId => text()();
  TextColumn get key => text()();
  TextColumn get label => text()();
  TextColumn get rawValue => text()();
  TextColumn get normalizedValue => text().nullable()();
  TextColumn get confirmedValue => text().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get confidence => real()();
  TextColumn get status => text()();
  TextColumn get source => text()();
  TextColumn get originalBoundingBox => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();
  @override
  Set<Column<Object>> get primaryKey => {userId, id};
}
