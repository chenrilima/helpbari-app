import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/medical_consultations.dart';

part 'medical_consultation_dao.g.dart';

@DriftAccessor(
  tables: [
    MedicalConsultations,
    MedicalConsultationExams,
    MedicalConsultationBodyCompositions,
  ],
)
class MedicalConsultationDao extends DatabaseAccessor<AppDatabase>
    with _$MedicalConsultationDaoMixin {
  MedicalConsultationDao(super.attachedDatabase);

  Future<List<MedicalConsultation>> getActiveByUser(String userId) =>
      (select(medicalConsultations)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.consultationAt)]))
          .get();

  Future<MedicalConsultation?> getByUserAndId(String userId, String id) =>
      (select(medicalConsultations)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<MedicalConsultation?> getByUserAndAppointmentId(
    String userId,
    String appointmentId,
  ) =>
      (select(medicalConsultations)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.appointmentId.equals(appointmentId) &
                  row.deletedAt.isNull(),
            )
            ..limit(1))
          .getSingleOrNull();

  Future<List<MedicalConsultation>> getPendingForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(medicalConsultations)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<List<MedicalConsultationExam>> getExamLinks(
    String userId,
    String consultationId,
  ) =>
      (select(medicalConsultationExams)..where(
            (row) =>
                row.userId.equals(userId) &
                row.medicalConsultationId.equals(consultationId),
          ))
          .get();

  Future<List<MedicalConsultationBodyComposition>> getBodyCompositionLinks(
    String userId,
    String consultationId,
  ) =>
      (select(medicalConsultationBodyCompositions)..where(
            (row) =>
                row.userId.equals(userId) &
                row.medicalConsultationId.equals(consultationId),
          ))
          .get();

  Future<void> upsertConsultation(MedicalConsultationsCompanion row) =>
      into(medicalConsultations).insertOnConflictUpdate(row);

  Future<void> replaceExamLinks(
    String userId,
    String consultationId,
    List<MedicalConsultationExamsCompanion> rows,
  ) => transaction(() async {
    await (delete(medicalConsultationExams)..where(
          (row) =>
              row.userId.equals(userId) &
              row.medicalConsultationId.equals(consultationId),
        ))
        .go();
    if (rows.isNotEmpty) {
      await batch((batch) => batch.insertAll(medicalConsultationExams, rows));
    }
  });

  Future<void> replaceBodyCompositionLinks(
    String userId,
    String consultationId,
    List<MedicalConsultationBodyCompositionsCompanion> rows,
  ) => transaction(() async {
    await (delete(medicalConsultationBodyCompositions)..where(
          (row) =>
              row.userId.equals(userId) &
              row.medicalConsultationId.equals(consultationId),
        ))
        .go();
    if (rows.isNotEmpty) {
      await batch(
        (batch) => batch.insertAll(medicalConsultationBodyCompositions, rows),
      );
    }
  });

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId, String repositoryKey) async {
    final row =
        await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
              (cursor) =>
                  cursor.userId.equals(userId) &
                  cursor.repositoryKey.equals(repositoryKey),
            ))
            .getSingleOrNull();
    return row?.lastPullAt;
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
