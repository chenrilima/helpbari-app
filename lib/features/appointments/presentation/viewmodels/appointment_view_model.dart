import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../application/appointment_reminder_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/appointment_use_cases_provider.dart';
import '../states/appointment_state.dart';

class AppointmentViewModel extends Notifier<AppointmentState> {
  late final UuidService _uuidService;
  late final ClockService _clock;
  late final AppointmentReminderService _reminders;
  late final AppointmentUseCases _useCases;

  @override
  AppointmentState build() {
    _uuidService = ref.read(uuidServiceProvider);
    _clock = ref.read(clockServiceProvider);
    _reminders = ref.read(appointmentReminderServiceProvider);
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
    await _reminders.scheduleIfEnabled(appointment);

    await loadAppointments();
  }

  Future<void> complete(String id) async {
    await _useCases.markAsCompleted(id);
    await _reminders.cancel(id);

    await loadAppointments();
  }

  Future<void> cancel(String id) async {
    await _useCases.cancel(id);
    await _reminders.cancel(id);

    await loadAppointments();
  }
}
