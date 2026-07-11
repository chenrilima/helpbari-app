import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/water_records.dart';

part 'water_dao.g.dart';

@DriftAccessor(tables: [WaterRecords])
class WaterDao extends DatabaseAccessor<AppDatabase> with _$WaterDaoMixin {
  WaterDao(super.attachedDatabase);

  Future<List<WaterRecord>> getActiveByUser(String userId) {
    return (select(waterRecords)
          ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)]))
        .get();
  }

  Future<WaterRecord?> getByUserAndId(String userId, String id) {
    return (select(waterRecords)
          ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<WaterRecord>> getPendingByUser(String userId) {
    return (select(waterRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<void> upsert(WaterRecordsCompanion record) {
    return into(waterRecords).insertOnConflictUpdate(record);
  }

  Future<void> upsertAll(Iterable<WaterRecordsCompanion> records) {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(waterRecords, records.toList());
    });
  }

  Future<void> deleteByUserAndId(String userId, String id) {
    return (delete(
      waterRecords,
    )..where((row) => row.userId.equals(userId) & row.id.equals(id))).go();
  }

  Future<T> inTransaction<T>(Future<T> Function() action) {
    return transaction(action);
  }
}
