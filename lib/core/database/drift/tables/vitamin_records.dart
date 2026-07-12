import 'package:drift/drift.dart';

@TableIndex(
  name: 'vitamin_user_deleted_schedule_idx',
  columns: {#userId, #deletedAt, #scheduleHour, #scheduleMinute},
)
@TableIndex(
  name: 'vitamin_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class VitaminRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  IntColumn get scheduleHour =>
      integer().customConstraint('CHECK (schedule_hour BETWEEN 0 AND 23)')();
  IntColumn get scheduleMinute =>
      integer().customConstraint('CHECK (schedule_minute BETWEEN 0 AND 59)')();
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
