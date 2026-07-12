import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/privacy_consent_records.dart';

part 'privacy_consent_dao.g.dart';

@DriftAccessor(tables: [PrivacyConsentRecords])
class PrivacyConsentDao extends DatabaseAccessor<AppDatabase>
    with _$PrivacyConsentDaoMixin {
  PrivacyConsentDao(super.attachedDatabase);

  Future<List<PrivacyConsentRecord>> getByUser(String userId) =>
      (select(privacyConsentRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.acceptedAt)]))
          .get();

  Future<PrivacyConsentRecord?> getByUserAndId(String userId, String id) =>
      (select(privacyConsentRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<List<PrivacyConsentRecord>> getPending(String userId) =>
      userId == 'anonymous'
      ? Future.value(const [])
      : (select(privacyConsentRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.syncStatus.isNotValue('synced'),
            ))
            .get();

  Future<void> upsert(PrivacyConsentRecordsCompanion value) =>
      into(privacyConsentRecords).insertOnConflictUpdate(value);

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId) async =>
      (await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.repositoryKey.equals('privacy_consents'),
              ))
              .getSingleOrNull())
          ?.lastPullAt;

  Future<void> saveCursor(String userId, DateTime at) => attachedDatabase
      .into(attachedDatabase.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          userId: userId,
          repositoryKey: 'privacy_consents',
          lastPullAt: Value(at),
          lastPushAt: Value(at),
          lastSyncAt: Value(at),
          status: const Value('success'),
        ),
      );
}
