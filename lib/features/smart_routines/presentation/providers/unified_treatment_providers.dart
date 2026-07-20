import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../application/unified_treatment_cutover_service.dart';
import '../../application/unified_treatment_migrator.dart';
import '../../application/unified_treatment_rollout.dart';

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
