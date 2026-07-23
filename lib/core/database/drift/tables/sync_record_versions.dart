import 'package:drift/drift.dart';

class SyncRecordVersions extends Table {
  TextColumn get userId => text()();
  TextColumn get repositoryKey => text()();
  TextColumn get recordId => text()();
  IntColumn get serverRevision => integer()();

  @override
  Set<Column<Object>> get primaryKey => {userId, repositoryKey, recordId};
}
