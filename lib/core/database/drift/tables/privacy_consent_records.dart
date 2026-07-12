import 'package:drift/drift.dart';

@TableIndex(
  name: 'privacy_consent_user_versions_idx',
  columns: {#userId, #termsVersion, #privacyVersion},
  unique: true,
)
@TableIndex(
  name: 'privacy_consent_user_updated_idx',
  columns: {#userId, #updatedAt},
)
class PrivacyConsentRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get termsVersion => text()();
  TextColumn get privacyVersion => text()();
  DateTimeColumn get acceptedAt => dateTime()();
  TextColumn get deviceId => text()();
  TextColumn get timezone => text()();
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
