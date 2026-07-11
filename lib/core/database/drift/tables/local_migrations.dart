import 'package:drift/drift.dart';

class LocalMigrations extends Table {
  TextColumn get migrationKey => text()();

  DateTimeColumn get completedAt => dateTime()();

  TextColumn get sourceChecksum => text().nullable()();

  IntColumn get importedCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {migrationKey};
}
