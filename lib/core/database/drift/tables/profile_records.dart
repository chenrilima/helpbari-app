import 'package:drift/drift.dart';

@TableIndex(name: 'profile_user_unique_idx', columns: {#userId}, unique: true)
@TableIndex(
  name: 'profile_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class ProfileRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  DateTimeColumn get birthDate => dateTime()();
  IntColumn get heightInCentimeters => integer()();
  RealColumn get initialWeight => real()();
  RealColumn get targetWeight => real().nullable()();
  DateTimeColumn get surgeryDate => dateTime()();
  TextColumn get surgeryType => text()();
  TextColumn get photoUrl => text().nullable()();
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
