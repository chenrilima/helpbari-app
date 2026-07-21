import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/medical_prescription_records.dart';

part 'medical_prescription_dao.g.dart';

@DriftAccessor(
  tables: [MedicalPrescriptionRecords, MedicalPrescriptionItemRecords],
)
class MedicalPrescriptionDao extends DatabaseAccessor<AppDatabase>
    with _$MedicalPrescriptionDaoMixin {
  MedicalPrescriptionDao(super.db);

  Stream<List<MedicalPrescriptionRecord>> watchActive(String userId) =>
      (select(medicalPrescriptionRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.prescribedAt)]))
          .watch();

  Future<List<MedicalPrescriptionRecord>> getActive(String userId) =>
      (select(medicalPrescriptionRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.prescribedAt)]))
          .get();

  Future<List<MedicalPrescriptionRecord>> getActiveLimited(
    String userId, {
    required int limit,
  }) =>
      (select(medicalPrescriptionRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.prescribedAt)])
            ..limit(limit))
          .get();

  Future<List<MedicalPrescriptionItemRecord>> getActiveItemsForPrescriptions(
    String userId,
    Iterable<String> prescriptionIds,
  ) {
    final ids = prescriptionIds.toList(growable: false);
    if (ids.isEmpty) return Future.value(const []);
    return (select(medicalPrescriptionItemRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) &
                row.prescriptionId.isIn(ids) &
                row.deletedAt.isNull(),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Future<int> countRequiringReview(String userId) async {
    final prescriptionQuery = selectOnly(medicalPrescriptionRecords)
      ..addColumns([medicalPrescriptionRecords.id])
      ..where(
        medicalPrescriptionRecords.userId.equals(userId) &
            medicalPrescriptionRecords.deletedAt.isNull() &
            medicalPrescriptionRecords.status.equals('requiresReview'),
      );
    final itemQuery = selectOnly(medicalPrescriptionItemRecords)
      ..addColumns([medicalPrescriptionItemRecords.prescriptionId])
      ..where(
        medicalPrescriptionItemRecords.userId.equals(userId) &
            medicalPrescriptionItemRecords.deletedAt.isNull() &
            medicalPrescriptionItemRecords.reviewStatus.equals('pending'),
      );
    final ids = <String>{
      for (final row in await prescriptionQuery.get())
        if (row.read(medicalPrescriptionRecords.id) case final String id) id,
      for (final row in await itemQuery.get())
        if (row.read(medicalPrescriptionItemRecords.prescriptionId)
            case final String id)
          id,
    };
    return ids.length;
  }

  Future<MedicalPrescriptionRecord?> getById(String userId, String id) =>
      (select(medicalPrescriptionRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<List<MedicalPrescriptionItemRecord>> getItems(
    String userId,
    String prescriptionId, {
    bool includeDeleted = false,
  }) =>
      (select(medicalPrescriptionItemRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.prescriptionId.equals(prescriptionId) &
                  (includeDeleted
                      ? const Constant(true)
                      : row.deletedAt.isNull()),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<List<MedicalPrescriptionRecord>> getPending(String userId) =>
      (select(medicalPrescriptionRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          ))
          .get();

  Future<void> upsertPrescription(MedicalPrescriptionRecordsCompanion row) =>
      into(medicalPrescriptionRecords).insertOnConflictUpdate(row);

  Future<void> upsertItem(MedicalPrescriptionItemRecordsCompanion row) =>
      into(medicalPrescriptionItemRecords).insertOnConflictUpdate(row);

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId, String key) async {
    final row =
        await (select(db.syncCursors)..where(
              (value) =>
                  value.userId.equals(userId) & value.repositoryKey.equals(key),
            ))
            .getSingleOrNull();
    return row?.lastPullAt;
  }

  Future<void> saveCursor(String userId, String key, DateTime at) =>
      into(db.syncCursors).insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          userId: userId,
          repositoryKey: key,
          lastPullAt: Value(at),
          lastPushAt: Value(at),
          lastSyncAt: Value(at),
          status: const Value('success'),
        ),
      );
}
