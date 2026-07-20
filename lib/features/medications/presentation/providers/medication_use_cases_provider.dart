import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../application/medication_reminder_service.dart';
import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../data/repositories/unified_medication_repositories.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return UnifiedMedicationRepository(
    UnifiedTreatmentStore(
      database: ref.read(appDatabaseProvider).requireValue,
      clock: ref.read(clockServiceProvider),
      userId: userId,
    ),
  );
});
final medicationLogRepositoryProvider = Provider<MedicationLogRepository>((
  ref,
) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return UnifiedMedicationLogRepository(
    UnifiedTreatmentStore(
      database: ref.read(appDatabaseProvider).requireValue,
      clock: ref.read(clockServiceProvider),
      userId: userId,
    ),
  );
});
final medicationUseCasesProvider = Provider<MedicationUseCases>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  final store = UnifiedTreatmentStore(
    database: ref.read(appDatabaseProvider).requireValue,
    clock: ref.read(clockServiceProvider),
    userId: userId,
  );
  return MedicationUseCases(
    ref.watch(medicationRepositoryProvider),
    ref.watch(medicationLogRepositoryProvider),
    (date) => store.pendingCount(TreatmentSpecialization.medication, date),
    (start, end) =>
        store.adherence(TreatmentSpecialization.medication, start, end),
  );
});
final medicationReminderServiceProvider = Provider<MedicationReminderService>((
  ref,
) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return MedicationReminderService(
    settingsUseCases: ref.read(settingsUseCasesProvider),
    scheduler: ref.read(notificationSchedulerProvider),
    clock: ref.read(clockServiceProvider),
    userId: userId,
  );
});
