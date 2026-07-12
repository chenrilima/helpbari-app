import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/cutover/medication_cutover_service.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../application/medication_reminder_service.dart';
import '../../data/datasources/drift_medication_local_datasource.dart';
import '../../data/datasources/drift_medication_log_local_datasource.dart';
import '../../data/repositories/drift_medication_log_repository.dart';
import '../../data/repositories/drift_medication_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return DriftMedicationRepository(() async {
    final db = await ref.read(appDatabaseProvider.future);
    if (userId != 'anonymous') {
      await MedicationCutoverService(db).attempt(userId);
    }
    return DriftMedicationLocalDatasource(
      dao: db.medicationDao,
      clock: ref.read(clockServiceProvider),
      userId: userId,
    );
  });
});
final medicationLogRepositoryProvider = Provider<MedicationLogRepository>((
  ref,
) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return DriftMedicationLogRepository(
    () async => DriftMedicationLogLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).medicationLogDao,
      clock: ref.read(clockServiceProvider),
      uuid: ref.read(uuidServiceProvider),
      userId: userId,
    ),
  );
});
final medicationUseCasesProvider = Provider<MedicationUseCases>(
  (ref) => MedicationUseCases(
    ref.watch(medicationRepositoryProvider),
    ref.watch(medicationLogRepositoryProvider),
  ),
);
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
