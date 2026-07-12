import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/database/drift/cutover/vitamin_cutover_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../application/vitamin_reminder_service.dart';
import '../../data/datasources/drift_vitamin_local_datasource.dart';
import '../../data/datasources/drift_vitamin_log_local_datasource.dart';
import '../../data/repositories/drift_vitamin_log_repository.dart';
import '../../data/repositories/drift_vitamin_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/vitamin_use_cases.dart';

final vitaminRepositoryProvider = Provider<VitaminRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return DriftVitaminRepository(() async {
    final database = await ref.read(appDatabaseProvider.future);
    if (userId != 'anonymous') {
      await VitaminCutoverService(database).attempt(userId);
    }
    return DriftVitaminLocalDatasource(
      dao: database.vitaminDao,
      clock: ref.read(clockServiceProvider),
      userId: userId,
    );
  });
});
final vitaminLogRepositoryProvider = Provider<VitaminLogRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return DriftVitaminLogRepository(
    () async => DriftVitaminLogLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).vitaminLogDao,
      clock: ref.read(clockServiceProvider),
      uuid: ref.read(uuidServiceProvider),
      userId: userId,
    ),
  );
});
final vitaminUseCasesProvider = Provider<VitaminUseCases>(
  (ref) => VitaminUseCases(
    ref.watch(vitaminRepositoryProvider),
    ref.watch(vitaminLogRepositoryProvider),
  ),
);
final vitaminReminderServiceProvider = Provider<VitaminReminderService>(
  (ref) => VitaminReminderService(
    settingsUseCases: ref.read(settingsUseCasesProvider),
    notifications: ref.read(localNotificationServiceProvider),
  ),
);
