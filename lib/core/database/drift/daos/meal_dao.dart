import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/meal_records.dart';

part 'meal_dao.g.dart';

@DriftAccessor(tables: [MealRecords])
class MealDao extends DatabaseAccessor<AppDatabase> with _$MealDaoMixin {
  MealDao(super.attachedDatabase);

  Future<List<MealRecord>> getActiveByUser(String userId) =>
      (select(mealRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.mealDate)]))
          .get();

  Future<List<MealRecord>> getActiveByUserInRange(
    String userId,
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) =>
      (select(mealRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.deletedAt.isNull() &
                  row.mealDate.isBiggerOrEqualValue(startInclusive) &
                  row.mealDate.isSmallerThanValue(endExclusive),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.mealDate)])
            ..limit(limit))
          .get();

  Future<MealRecord?> getByUserAndId(String userId, String id) =>
      (select(mealRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<List<MealRecord>> getPendingForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(mealRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<void> upsert(MealRecordsCompanion record) =>
      into(mealRecords).insertOnConflictUpdate(record);
  Future<void> upsertAll(Iterable<MealRecordsCompanion> records) => batch(
    (batch) => batch.insertAllOnConflictUpdate(mealRecords, records.toList()),
  );
  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId, String repositoryKey) async {
    final cursor =
        await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.repositoryKey.equals(repositoryKey),
            ))
            .getSingleOrNull();
    return cursor?.lastPullAt;
  }

  Future<void> saveCursor(
    String userId,
    String repositoryKey,
    DateTime completedAt,
  ) => attachedDatabase
      .into(attachedDatabase.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          userId: userId,
          repositoryKey: repositoryKey,
          lastPullAt: Value(completedAt),
          lastPushAt: Value(completedAt),
          lastSyncAt: Value(completedAt),
          status: const Value('success'),
        ),
      );
}
