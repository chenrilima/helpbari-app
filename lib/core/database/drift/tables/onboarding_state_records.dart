import 'package:drift/drift.dart';

@TableIndex(
  name: 'onboarding_state_user_active_unique_idx',
  columns: {#userId},
  unique: true,
)
@TableIndex(
  name: 'onboarding_state_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class OnboardingStateRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get onboardingVersion => integer()();
  TextColumn get status => text()();
  TextColumn get currentStepId => text().nullable()();
  TextColumn get completedStepIdsJson => text()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
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
