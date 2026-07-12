import 'package:drift/drift.dart';

@TableIndex(
  name: 'appointment_user_deleted_date_idx',
  columns: {#userId, #deletedAt, #appointmentAt},
)
@TableIndex(
  name: 'appointment_user_status_date_idx',
  columns: {#userId, #status, #appointmentAt},
)
@TableIndex(
  name: 'appointment_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class AppointmentRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  DateTimeColumn get appointmentAt => dateTime()();
  TextColumn get doctorName => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
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
