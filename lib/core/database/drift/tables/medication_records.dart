import 'package:drift/drift.dart';

@TableIndex(
  name: 'medication_user_deleted_schedule_idx',
  columns: {#userId, #deletedAt, #scheduleHour, #scheduleMinute},
)
@TableIndex(
  name: 'medication_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class MedicationRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  IntColumn get scheduleHour => integer().customConstraint(
    'NOT NULL CHECK (schedule_hour BETWEEN 0 AND 23)',
  )();
  IntColumn get scheduleMinute => integer().customConstraint(
    'NOT NULL CHECK (schedule_minute BETWEEN 0 AND 59)',
  )();
  TextColumn get dosage => text().nullable()();
  TextColumn get notes => text().nullable()();
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
