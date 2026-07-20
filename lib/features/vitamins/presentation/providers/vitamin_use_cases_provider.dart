import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../application/vitamin_reminder_service.dart';
import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../data/repositories/unified_vitamin_repositories.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/vitamin_use_cases.dart';

final vitaminRepositoryProvider = Provider<VitaminRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return UnifiedVitaminRepository(
    UnifiedTreatmentStore(
      database: ref.read(appDatabaseProvider).requireValue,
      clock: ref.read(clockServiceProvider),
      userId: userId,
    ),
  );
});
final vitaminLogRepositoryProvider = Provider<VitaminLogRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return UnifiedVitaminLogRepository(
    UnifiedTreatmentStore(
      database: ref.read(appDatabaseProvider).requireValue,
      clock: ref.read(clockServiceProvider),
      userId: userId,
    ),
  );
});
final vitaminUseCasesProvider = Provider<VitaminUseCases>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  final store = UnifiedTreatmentStore(
    database: ref.read(appDatabaseProvider).requireValue,
    clock: ref.read(clockServiceProvider),
    userId: userId,
  );
  return VitaminUseCases(
    ref.watch(vitaminRepositoryProvider),
    ref.watch(vitaminLogRepositoryProvider),
    (date) => store.pendingCount(TreatmentSpecialization.vitamin, date),
    (start, end) =>
        store.adherence(TreatmentSpecialization.vitamin, start, end),
  );
});
final vitaminReminderServiceProvider = Provider<VitaminReminderService>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return VitaminReminderService(
    settingsUseCases: ref.read(settingsUseCasesProvider),
    scheduler: ref.read(notificationSchedulerProvider),
    clock: ref.read(clockServiceProvider),
    userId: userId,
  );
});
