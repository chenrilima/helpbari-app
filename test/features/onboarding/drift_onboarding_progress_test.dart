import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/onboarding/data/datasources/drift_onboarding_progress_datasource.dart';
import 'package:helpbari/features/onboarding/data/dtos/onboarding_progress_dto.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('persists one versioned progress record per user', () async {
    final first = _datasource(database, 'user-a');
    final second = _datasource(database, 'user-b');

    await first.save(_dto('state-a', 'user-a'));
    await second.save(_dto('state-b', 'user-b'));

    expect((await first.get())?.progress.currentStepId, 'basicProfile');
    expect((await second.get())?.progress.userId, 'user-b');
    expect(
      await database.select(database.onboardingStateRecords).get(),
      hasLength(2),
    );
  });

  test(
    'rejects cross-user writes and applies only newer remote state',
    () async {
      final datasource = _datasource(database, 'user-a');
      await datasource.save(_dto('state-a', 'user-a'));

      await expectLater(
        datasource.save(_dto('state-b', 'user-b')),
        throwsStateError,
      );
      expect(
        await datasource.applyRemote(
          _dto('state-a', 'user-a', updatedAt: DateTime.utc(2025)),
        ),
        isFalse,
      );
      expect(
        await datasource.applyRemoteAndMarkSynced(
          _dto(
            'state-a',
            'user-a',
            updatedAt: DateTime.utc(2027),
            status: OnboardingProgressStatus.completed,
          ),
        ),
        isTrue,
      );
      expect(
        (await datasource.get())?.progress.status,
        OnboardingProgressStatus.completed,
      );
    },
  );
}

DriftOnboardingProgressDatasource _datasource(
  AppDatabase database,
  String userId,
) => DriftOnboardingProgressDatasource(
  dao: database.onboardingStateDao,
  userId: userId,
);

OnboardingProgressDto _dto(
  String id,
  String userId, {
  DateTime? updatedAt,
  OnboardingProgressStatus status = OnboardingProgressStatus.inProgress,
}) {
  final createdAt = DateTime.utc(2026, 7, 21);
  final changedAt = updatedAt ?? createdAt;
  return OnboardingProgressDto(
    progress: OnboardingProgress(
      id: id,
      userId: userId,
      onboardingVersion: OnboardingV1Contract.version,
      status: status,
      currentStepId: status == OnboardingProgressStatus.completed
          ? null
          : 'basicProfile',
      completedStepIds: const {'welcome', 'legalConsents'},
      startedAt: createdAt,
      completedAt: status == OnboardingProgressStatus.completed
          ? changedAt
          : null,
      createdAt: createdAt,
      updatedAt: changedAt,
    ),
    syncMetadata: SyncMetadata(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: changedAt,
      syncStatus: SyncStatus.synced,
    ),
  );
}
