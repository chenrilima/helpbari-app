import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/database/drift/cutover/appointment_cutover_service.dart';
import '../../../../core/database/drift/migrations/appointment_legacy_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../application/appointment_reminder_service.dart';
import '../../data/datasources/local_appointment_datasource.dart';
import '../../data/datasources/drift_appointment_local_datasource.dart';
import '../../data/repositories/drift_primary_appointment_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  ref.watch(repositoryBackendProvider);
  final userId = ref.watch(authSessionProvider)?.id;
  final effectiveUserId = userId ?? anonymousAppointmentUserId;
  final storage = ref.watch(localStorageServiceProvider);
  return DriftPrimaryAppointmentRepository(
    drift: () async => DriftAppointmentLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).appointmentDao,
      clock: ref.read(clockServiceProvider),
      userId: effectiveUserId,
    ),
    fallback: LocalAppointmentDatasource(
      database: ref.watch(localDatabaseProvider),
      clock: ref.watch(clockServiceProvider),
    ),
    logger: ref.watch(loggerServiceProvider),
    ensureCutover: () async {
      if (userId != null) {
        await AppointmentCutoverService(
          database: await ref.read(appDatabaseProvider.future),
          storage: storage,
        ).attempt(userId);
      }
    },
    hasCutoverMirror: () =>
        userId != null &&
        AppointmentCutoverService.isCompletedMirrorFor(storage, userId),
  );
});

final appointmentUseCasesProvider = Provider<AppointmentUseCases>(
  (ref) => AppointmentUseCases(ref.watch(appointmentRepositoryProvider)),
);

final appointmentReminderServiceProvider = Provider<AppointmentReminderService>(
  (ref) {
    final userId =
        ref.watch(authSessionProvider)?.id ?? anonymousAppointmentUserId;
    return AppointmentReminderService(
      settingsUseCases: ref.read(settingsUseCasesProvider),
      scheduler: ref.read(notificationSchedulerProvider),
      userId: userId,
    );
  },
);
