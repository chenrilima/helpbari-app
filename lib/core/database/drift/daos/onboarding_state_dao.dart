import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/onboarding_state_records.dart';

part 'onboarding_state_dao.g.dart';

@DriftAccessor(tables: [OnboardingStateRecords])
class OnboardingStateDao extends DatabaseAccessor<AppDatabase>
    with _$OnboardingStateDaoMixin {
  OnboardingStateDao(super.attachedDatabase);

  Future<OnboardingStateRecord?> getByUser(String userId) =>
      (select(onboardingStateRecords)
            ..where((row) => row.userId.equals(userId)))
          .getSingleOrNull();

  Future<List<OnboardingStateRecord>> getPending(String userId) =>
      (select(onboardingStateRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.syncStatus.isNotValue('synced'),
          ))
          .get();

  Future<void> upsert(OnboardingStateRecordsCompanion value) =>
      into(onboardingStateRecords).insertOnConflictUpdate(value);

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId) async =>
      (await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.repositoryKey.equals('onboarding_states'),
              ))
              .getSingleOrNull())
          ?.lastPullAt;

  Future<void> saveCursor(String userId, DateTime at) => attachedDatabase
      .into(attachedDatabase.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          userId: userId,
          repositoryKey: 'onboarding_states',
          lastPullAt: Value(at),
          lastPushAt: Value(at),
          lastSyncAt: Value(at),
          status: const Value('success'),
        ),
      );
}
