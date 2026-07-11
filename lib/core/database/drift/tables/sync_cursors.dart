import 'package:drift/drift.dart';

class SyncCursors extends Table {
  TextColumn get userId => text()();

  TextColumn get repositoryKey => text()();

  DateTimeColumn get lastPullAt => dateTime().nullable()();

  DateTimeColumn get lastPushAt => dateTime().nullable()();

  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  TextColumn get status => text().withDefault(const Constant('idle'))();

  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, repositoryKey};
}
