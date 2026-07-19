import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/document_intelligence_records.dart';

part 'document_intelligence_dao.g.dart';

@DriftAccessor(
  tables: [
    DocumentInputRecords,
    DocumentProcessingRecords,
    ExtractedFieldRecords,
  ],
)
class DocumentIntelligenceDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentIntelligenceDaoMixin {
  DocumentIntelligenceDao(super.attachedDatabase);

  Future<T> inTransaction<T>(Future<T> Function() action) {
    return transaction(action);
  }

  Future<void> upsertDocument(DocumentInputRecordsCompanion value) =>
      into(documentInputRecords).insertOnConflictUpdate(value);

  Future<void> updateDocumentRemotePath({
    required String userId,
    required String documentId,
    required String remotePath,
    required DateTime updatedAt,
  }) async {
    await (update(documentInputRecords)..where(
          (row) => row.userId.equals(userId) & row.id.equals(documentId),
        ))
        .write(
          DocumentInputRecordsCompanion(
            remotePath: Value(remotePath),
            updatedAt: Value(updatedAt),
            syncStatus: const Value('pendingUpdate'),
          ),
        );
  }

  Future<void> upsertProcessing(DocumentProcessingRecordsCompanion value) =>
      into(documentProcessingRecords).insertOnConflictUpdate(value);

  Future<void> replaceFields(
    String userId,
    String processingId,
    List<ExtractedFieldRecordsCompanion> values,
  ) => transaction(() async {
    await (delete(extractedFieldRecords)..where(
          (row) =>
              row.userId.equals(userId) & row.processingId.equals(processingId),
        ))
        .go();
    if (values.isNotEmpty) {
      await batch((batch) => batch.insertAll(extractedFieldRecords, values));
    }
  });

  Future<DocumentInputRecord?> getDocument(String userId, String id) =>
      (select(documentInputRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.id.equals(id) &
                row.deletedAt.isNull(),
          ))
          .getSingleOrNull();

  Future<List<DocumentInputRecord>> getDocuments(String userId) =>
      (select(documentInputRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .get();

  Future<DocumentProcessingRecord?> getLatestProcessingForDocument(
    String userId,
    String documentId,
  ) =>
      (select(documentProcessingRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.documentId.equals(documentId) &
                  row.deletedAt.isNull(),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<DocumentProcessingRecord?> getProcessing(String userId, String id) =>
      (select(documentProcessingRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.id.equals(id) &
                row.deletedAt.isNull(),
          ))
          .getSingleOrNull();

  Future<List<ExtractedFieldRecord>> getFields(
    String userId,
    String processingId,
  ) =>
      (select(extractedFieldRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.processingId.equals(processingId) &
                row.deletedAt.isNull(),
          ))
          .get();

  Future<List<DocumentProcessingRecord>> getPendingProcessings(String userId) =>
      (select(documentProcessingRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotIn(['synced']),
          ))
          .get();

  Future<DocumentProcessingRecord?> getAnyProcessing(
    String userId,
    String id,
  ) =>
      (select(documentProcessingRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<void> markProcessingSynced(
    String userId,
    String processingId,
    DateTime at,
  ) async {
    final processing = await getAnyProcessing(userId, processingId);
    if (processing == null) return;
    await transaction(() async {
      await (update(documentProcessingRecords)..where(
            (row) => row.userId.equals(userId) & row.id.equals(processingId),
          ))
          .write(
            DocumentProcessingRecordsCompanion(
              syncStatus: const Value('synced'),
              updatedAt: Value(at),
            ),
          );
      await (update(documentInputRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.id.equals(processing.documentId),
          ))
          .write(
            DocumentInputRecordsCompanion(
              syncStatus: const Value('synced'),
              updatedAt: Value(at),
            ),
          );
      await (update(extractedFieldRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.processingId.equals(processingId) &
                row.deletedAt.isNull(),
          ))
          .write(
            ExtractedFieldRecordsCompanion(
              syncStatus: const Value('synced'),
              updatedAt: Value(at),
            ),
          );
    });
  }

  Future<void> markProcessingFailed(
    String userId,
    String processingId,
    String error,
  ) async {
    final processing = await getAnyProcessing(userId, processingId);
    if (processing == null) return;
    final document = await getDocument(userId, processing.documentId);
    await transaction(() async {
      await (update(documentProcessingRecords)..where(
            (row) => row.userId.equals(userId) & row.id.equals(processingId),
          ))
          .write(
            const DocumentProcessingRecordsCompanion(
              syncStatus: Value('failed'),
            ),
          );
      await (update(documentInputRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.id.equals(processing.documentId),
          ))
          .write(
            DocumentInputRecordsCompanion(
              syncStatus: const Value('failed'),
              previousSyncStatus: Value(processing.syncStatus),
              syncAttempts: Value((document?.syncAttempts ?? 0) + 1),
              lastSyncError: Value(error),
            ),
          );
    });
  }

  Future<DateTime?> getLastPullAt(String userId, String repositoryKey) async {
    final row =
        await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.repositoryKey.equals(repositoryKey),
            ))
            .getSingleOrNull();
    return row?.lastPullAt;
  }

  Future<void> saveCursor(
    String userId,
    String repositoryKey,
    DateTime completedAt,
  ) {
    return attachedDatabase
        .into(attachedDatabase.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(
            userId: userId,
            repositoryKey: repositoryKey,
            lastPullAt: Value(completedAt),
            lastPushAt: Value(completedAt),
            lastSyncAt: Value(completedAt),
          ),
        );
  }

  Future<void> tombstoneDocument(String userId, String id, DateTime at) async {
    await (update(
      documentInputRecords,
    )..where((row) => row.userId.equals(userId) & row.id.equals(id))).write(
      DocumentInputRecordsCompanion(
        deletedAt: Value(at),
        updatedAt: Value(at),
        syncStatus: const Value('pendingDelete'),
      ),
    );
  }
}
