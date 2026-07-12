import 'package:drift/drift.dart';

@TableIndex(
  name: 'vitamin_log_user_date_idx',
  columns: {#userId, #logDate, #deletedAt},
)
@TableIndex(
  name: 'vitamin_log_user_vitamin_date_idx',
  columns: {#userId, #vitaminId, #logDate},
  unique: true,
)
@TableIndex(
  name: 'vitamin_log_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class VitaminLogRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get vitaminId => text()();
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
