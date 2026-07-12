import 'package:drift/drift.dart';

@TableIndex(
  name: 'meal_user_deleted_date_idx',
  columns: {#userId, #deletedAt, #mealDate},
)
@TableIndex(
  name: 'meal_user_type_date_idx',
  columns: {#userId, #type, #mealDate},
)
@TableIndex(
  name: 'meal_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class MealRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  DateTimeColumn get mealDate => dateTime()();
  TextColumn get notes => text().nullable()();
  IntColumn get proteinGrams => integer().nullable().customConstraint(
    'CHECK (protein_grams IS NULL OR protein_grams >= 0)',
  )();
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
