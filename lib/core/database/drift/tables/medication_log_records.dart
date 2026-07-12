import 'package:drift/drift.dart';

@TableIndex(
  name: 'medication_log_user_date_idx',
  columns: {#userId, #logDate, #deletedAt},
)
@TableIndex(
  name: 'medication_log_user_medication_date_idx',
  columns: {#userId, #medicationId, #logDate},
  unique: true,
)
@TableIndex(
  name: 'medication_log_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class MedicationLogRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get medicationId => text()();
  DateTimeColumn get logDate => dateTime()();
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
