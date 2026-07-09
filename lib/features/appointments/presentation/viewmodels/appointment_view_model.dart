import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/appointment_use_cases_provider.dart';
import '../states/appointment_state.dart';

class AppointmentViewModel extends Notifier<AppointmentState> {
  late final UuidService _uuidService;
  late final ClockService _clock;
  late final LocalNotificationService _notifications;
  late final AppointmentUseCases _useCases;

  @override
  AppointmentState build() {
    _uuidService = ref.read(uuidServiceProvider);
    _clock = ref.read(clockServiceProvider);
    _notifications = ref.read(localNotificationServiceProvider);
    _useCases = ref.read(appointmentUseCasesProvider);

    return const AppointmentState();
  }

  Future<void> loadAppointments() async {
    state = state.copyWith(isLoading: true);

    final appointments = await _useCases.getAll();

    state = state.copyWith(appointments: appointments, isLoading: false);
  }

  Future<void> createAppointment({
    required String title,
    required DateTime date,
    String? doctorName,
    String? location,
    String? notes,
  }) async {
    final appointment = Appointment(
      id: _uuidService.generate(),
      title: title,
      date: AppointmentDate(date, clock: _clock),
      doctorName: doctorName,
      location: location,
      notes: notes,
    );

    await _useCases.save(appointment);
    await _scheduleReminderIfEnabled(appointment);

    await loadAppointments();
  }

  Future<void> complete(String id) async {
    await _useCases.markAsCompleted(id);
    await _notifications.cancelPayload(
      LocalNotificationPayload(
        source: NotificationSource.appointment,
        entityId: id,
      ),
    );

    await loadAppointments();
  }

  Future<void> cancel(String id) async {
    await _useCases.cancel(id);
    await _notifications.cancelPayload(
      LocalNotificationPayload(
        source: NotificationSource.appointment,
        entityId: id,
      ),
    );

    await loadAppointments();
  }

  Future<void> _scheduleReminderIfEnabled(Appointment appointment) async {
    final settings = await ref.read(settingsUseCasesProvider).getSettings();

    if (!settings.appointmentRemindersEnabled || !appointment.isUpcoming) {
      return;
    }

    await _notifications.scheduleOnce(
      NotificationSchedules.appointment(appointment),
    );
  }
}
