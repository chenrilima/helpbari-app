import '../../../../core/sync/sync.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../../domain/repositories/onboarding_progress_repository.dart';
import '../datasources/drift_onboarding_progress_datasource.dart';
import '../dtos/onboarding_progress_dto.dart';

final class DriftOnboardingProgressRepository
    implements OnboardingProgressRepository {
  const DriftOnboardingProgressRepository({
    required DriftOnboardingProgressDatasource datasource,
    required DateTime Function() now,
  }) : _datasource = datasource,
       _now = now;

  final DriftOnboardingProgressDatasource _datasource;
  final DateTime Function() _now;

  @override
  Future<OnboardingProgress?> getForUser() async =>
      (await _datasource.get())?.progress;

  @override
  Future<void> save(OnboardingProgress progress) async {
    final existing = await _datasource.get();
    final now = _now().toUtc();
    await _datasource.save(
      OnboardingProgressDto(
        progress: progress.copyWith(updatedAt: now),
        syncMetadata: SyncMetadata(
          id: progress.id,
          userId: progress.userId,
          createdAt: existing?.syncMetadata.createdAt ?? progress.createdAt,
          updatedAt: now,
          deletedAt: progress.deletedAt,
          syncStatus: existing == null
              ? SyncStatus.pendingCreate
              : SyncStatus.pendingUpdate,
        ),
      ),
    );
  }
}
