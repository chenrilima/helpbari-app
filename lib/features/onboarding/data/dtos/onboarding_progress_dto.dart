import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/onboarding_progress.dart';

final class OnboardingProgressDto {
  const OnboardingProgressDto({
    required this.progress,
    required this.syncMetadata,
  });

  final OnboardingProgress progress;
  final SyncMetadata syncMetadata;

  factory OnboardingProgressDto.fromDrift(OnboardingStateRecord row) =>
      OnboardingProgressDto(
        progress: OnboardingProgress(
          id: row.id,
          userId: row.userId,
          onboardingVersion: row.onboardingVersion,
          status: OnboardingProgressStatus.values.firstWhere(
            (value) => value.name == row.status,
            orElse: () => OnboardingProgressStatus.needsReview,
          ),
          currentStepId: row.currentStepId,
          completedStepIds: _stepIds(row.completedStepIdsJson),
          startedAt: row.startedAt,
          completedAt: row.completedAt,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
          deletedAt: row.deletedAt,
        ),
        syncMetadata: SyncMetadata(
          id: row.id,
          userId: row.userId,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
          deletedAt: row.deletedAt,
          syncStatus: SyncStatus.fromName(row.syncStatus),
        ),
      );

  factory OnboardingProgressDto.fromSupabase(Map<String, dynamic> row) {
    DateTime? optionalDate(String key) =>
        row[key] == null ? null : DateTime.parse(row[key] as String).toUtc();
    final createdAt = DateTime.parse(row['created_at'] as String).toUtc();
    final updatedAt = DateTime.parse(row['updated_at'] as String).toUtc();
    return OnboardingProgressDto(
      progress: OnboardingProgress(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        onboardingVersion: row['onboarding_version'] as int,
        status: OnboardingProgressStatus.values.firstWhere(
          (value) => value.name == row['status'],
          orElse: () => OnboardingProgressStatus.needsReview,
        ),
        currentStepId: row['current_step_id'] as String?,
        completedStepIds:
            (row['completed_step_ids'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toSet(),
        startedAt: optionalDate('started_at'),
        completedAt: optionalDate('completed_at'),
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: optionalDate('deleted_at'),
      ),
      syncMetadata: SyncMetadata(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: optionalDate('deleted_at'),
        syncStatus: SyncStatus.synced,
        serverRevision: row['server_revision'] as int?,
      ),
    );
  }

  OnboardingStateRecordsCompanion toDrift() => OnboardingStateRecordsCompanion(
    id: Value(progress.id),
    userId: Value(progress.userId),
    onboardingVersion: Value(progress.onboardingVersion),
    status: Value(progress.status.name),
    currentStepId: Value(progress.currentStepId),
    completedStepIdsJson: Value(
      jsonEncode(progress.completedStepIds.toList()..sort()),
    ),
    startedAt: Value(progress.startedAt),
    completedAt: Value(progress.completedAt),
    createdAt: Value(syncMetadata.createdAt),
    updatedAt: Value(syncMetadata.updatedAt),
    deletedAt: Value(syncMetadata.deletedAt),
    syncStatus: Value(syncMetadata.syncStatus.name),
  );

  Map<String, Object?> toSupabase() => {
    'id': progress.id,
    'user_id': progress.userId,
    'onboarding_version': progress.onboardingVersion,
    'status': progress.status.name,
    'current_step_id': progress.currentStepId,
    'completed_step_ids': progress.completedStepIds.toList()..sort(),
    'started_at': progress.startedAt?.toUtc().toIso8601String(),
    'completed_at': progress.completedAt?.toUtc().toIso8601String(),
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  static Set<String> _stepIds(String encoded) {
    try {
      return (jsonDecode(encoded) as List<dynamic>).whereType<String>().toSet();
    } on FormatException {
      return <String>{};
    }
  }
}
