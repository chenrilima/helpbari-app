import 'package:drift/drift.dart';

@TableIndex(name: 'settings_user_unique_idx', columns: {#userId}, unique: true)
@TableIndex(
  name: 'settings_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class SettingsRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get dailyWaterGoalMl =>
      integer().withDefault(const Constant(2000))();
  BoolColumn get vitaminRemindersEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get medicationRemindersEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get appointmentRemindersEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get mealTrackingEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get treatmentTrackingEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get waterTrackingEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get weightTrackingEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get weightUnit => text().withDefault(const Constant('kg'))();
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
