import 'package:drift/drift.dart';

@TableIndex(
  name: 'water_user_deleted_recorded_idx',
  columns: {#userId, #deletedAt, #recordedAt},
)
@TableIndex(
  name: 'water_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class WaterRecords extends Table {
  TextColumn get id => text()();

  TextColumn get userId => text()();

  IntColumn get amountMl =>
      integer().customConstraint('NOT NULL CHECK (amount_ml > 0)')();

  DateTimeColumn get recordedAt => dateTime()();

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
