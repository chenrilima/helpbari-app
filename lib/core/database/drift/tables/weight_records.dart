import 'package:drift/drift.dart';

@TableIndex(
  name: 'weight_user_deleted_recorded_idx',
  columns: {#userId, #deletedAt, #recordedAt},
)
@TableIndex(
  name: 'weight_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class WeightRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  RealColumn get weightKg =>
      real().customConstraint('NOT NULL CHECK (weight_kg > 0)')();
  DateTimeColumn get recordedAt => dateTime()();
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
