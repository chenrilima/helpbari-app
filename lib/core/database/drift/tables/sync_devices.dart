import 'package:drift/drift.dart';

class SyncDevices extends Table {
  TextColumn get deviceId => text()();

  TextColumn get appVersion => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}
