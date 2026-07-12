import 'package:drift/drift.dart';

class MedicationCutovers extends Table {
  TextColumn get userId => text()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get databaseSchemaVersion => integer()();
  IntColumn get migratedMedicationCount => integer()();
  IntColumn get migratedLogCount => integer()();
  @override
  Set<Column<Object>> get primaryKey => {userId};
}
