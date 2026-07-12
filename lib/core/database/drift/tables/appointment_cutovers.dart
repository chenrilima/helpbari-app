import 'package:drift/drift.dart';

class AppointmentCutovers extends Table {
  TextColumn get migrationKey => text()();
  IntColumn get version => integer()();
  TextColumn get userId => text()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get checksum => text()();
  IntColumn get recordCount => integer()();
  IntColumn get databaseSchemaVersion => integer()();
  @override
  Set<Column<Object>> get primaryKey => {migrationKey, userId};
}
