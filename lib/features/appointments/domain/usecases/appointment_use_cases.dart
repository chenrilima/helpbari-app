import '../entities/entities.dart';
import '../models/appointment_summary.dart';
import '../repositories/repositories.dart';
import '../value_objects/value_objects.dart';

class AppointmentUseCases {
  const AppointmentUseCases(this._repository);

  final AppointmentRepository _repository;

  Future<List<Appointment>> getAll() {
    return _repository.getAll();
  }

  Future<List<Appointment>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    int limit = 500,
  }) {
    final repository = _repository;
    if (repository is! AppointmentRangeRepository) {
      throw StateError('Consulta de consultas por intervalo indisponível.');
    }
    return (repository as AppointmentRangeRepository).getByPeriod(
      startInclusive,
      endExclusive,
      limit: limit,
    );
  }

  Future<void> save(Appointment appointment) {
    return _repository.save(appointment);
  }

  Future<void> update(Appointment appointment) {
    return _repository.update(appointment);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<void> markAsCompleted(String id) async {
    final appointments = await _repository.getAll();
    final appointment = appointments.where((item) => item.id == id).firstOrNull;

    if (appointment == null) return;

    await _repository.update(
      appointment.copyWith(status: AppointmentStatus.completed),
    );
  }

  Future<void> cancel(String id) async {
    final appointments = await _repository.getAll();
    final appointment = appointments.where((item) => item.id == id).firstOrNull;

    if (appointment == null) return;

    await _repository.update(
      appointment.copyWith(status: AppointmentStatus.canceled),
    );
  }

  Future<AppointmentSummary> getSummary() async {
    final appointments = await _repository.getAll();

    final upcomingAppointments = appointments
        .where((appointment) => appointment.isUpcoming)
        .toList();

    return AppointmentSummary(
      nextAppointment: upcomingAppointments.isEmpty
          ? null
          : upcomingAppointments.first,
      hasAppointments: appointments.isNotEmpty,
    );
  }
}
