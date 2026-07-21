import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../application/unified_treatment_cutover_service.dart';
import '../../application/unified_treatment_migrator.dart';
import '../../application/unified_treatment_rollout.dart';
import '../../application/notification_platform.dart';
import '../../data/repositories/drift_notification_platform_repository.dart';
import '../../data/repositories/drift_occurrence_window_service.dart';
import '../../data/repositories/drift_treatment_query_service.dart';
import '../../domain/services/treatment_query_models.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final unifiedTreatmentRolloutProvider =
    FutureProvider<UnifiedTreatmentRolloutRepository>((ref) async {
      return UnifiedTreatmentRolloutRepository(
        await ref.watch(appDatabaseProvider.future),
      );
    });

final unifiedTreatmentMigratorProvider =
    FutureProvider<UnifiedTreatmentMigrator>(
      (ref) async => UnifiedTreatmentMigrator(
        database: await ref.watch(appDatabaseProvider.future),
      ),
    );

final unifiedTreatmentCutoverProvider =
    FutureProvider<UnifiedTreatmentCutoverService>((ref) async {
      final database = await ref.watch(appDatabaseProvider.future);
      return UnifiedTreatmentCutoverService(
        database: database,
        rollout: UnifiedTreatmentRolloutRepository(database),
      );
    });

final unifiedTreatmentRemoteSyncEnabledProvider = FutureProvider<bool>((
  ref,
) async {
  final rollout = await ref.watch(unifiedTreatmentRolloutProvider.future);
  return rollout.isEnabled(
    UnifiedTreatmentFlag.remoteSyncEnabled,
    ref.read(clockServiceProvider).now().toUtc(),
  );
});

final treatmentAdherenceQueryServiceProvider =
    FutureProvider<TreatmentAdherenceQueryService>((ref) async {
      final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
      final database = await ref.watch(appDatabaseProvider.future);
      final delegate = DriftTreatmentAdherenceQueryService(
        database: database,
        userId: userId,
        clock: ref.watch(clockServiceProvider),
      );
      return MaterializingTreatmentAdherenceQueryService(
        occurrences: DriftOccurrenceWindowService(
          database: database,
          userId: userId,
          clock: ref.watch(clockServiceProvider),
        ),
        delegate: delegate,
      );
    });

final notificationPlatformRepositoryProvider =
    FutureProvider<DriftNotificationPlatformRepository>((ref) async {
      return DriftNotificationPlatformRepository(
        database: await ref.watch(appDatabaseProvider.future),
        clock: ref.watch(clockServiceProvider),
      );
    });

final occurrenceWindowServiceProvider =
    FutureProvider<DriftOccurrenceWindowService>((ref) async {
      final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
      return DriftOccurrenceWindowService(
        database: await ref.watch(appDatabaseProvider.future),
        userId: userId,
        clock: ref.watch(clockServiceProvider),
      );
    });

final notificationV2ReconcilerProvider =
    FutureProvider<NotificationProjectionReconciler>((ref) async {
      final repository = await ref.watch(
        notificationPlatformRepositoryProvider.future,
      );
      return NotificationProjectionReconciler(
        manifest: repository,
        scheduler: ref.watch(notificationSchedulerProvider),
      );
    });

final notificationActionHandlerProvider =
    FutureProvider<NotificationActionHandler>((ref) async {
      final repository = await ref.watch(
        notificationPlatformRepositoryProvider.future,
      );
      return NotificationActionHandler(
        inbox: repository,
        commands: repository,
        scheduler: ref.watch(notificationSchedulerProvider),
        manifest: repository,
      );
    });
