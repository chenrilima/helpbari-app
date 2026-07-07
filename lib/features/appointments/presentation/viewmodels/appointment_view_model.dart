import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/appointment_use_cases_provider.dart';
import '../states/appointment_state.dart';

class AppointmentViewModel extends Notifier<AppointmentState> {
  final _uuid = const Uuid();

  late final AppointmentUseCases _useCases;

  @override
  AppointmentState build() {
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
      id: _uuid.v4(),
      title: title,
      date: AppointmentDate(date),
      doctorName: doctorName,
      location: location,
      notes: notes,
    );

    await _useCases.save(appointment);

    await loadAppointments();
  }

  Future<void> complete(String id) async {
    await _useCases.markAsCompleted(id);

    await loadAppointments();
  }

  Future<void> cancel(String id) async {
    await _useCases.cancel(id);

    await loadAppointments();
  }
}
