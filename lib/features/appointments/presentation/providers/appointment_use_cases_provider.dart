import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../application/appointment_reminder_service.dart';
import '../../data/datasources/local_appointment_datasource.dart';
import '../../data/repositories/local_appointment_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.local => LocalAppointmentRepository(
      LocalAppointmentDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Appointment Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});

final appointmentUseCasesProvider = Provider<AppointmentUseCases>(
  (ref) => AppointmentUseCases(ref.read(appointmentRepositoryProvider)),
);

final appointmentReminderServiceProvider = Provider<AppointmentReminderService>(
  (ref) => AppointmentReminderService(
    settingsUseCases: ref.read(settingsUseCasesProvider),
    notifications: ref.read(localNotificationServiceProvider),
  ),
);
