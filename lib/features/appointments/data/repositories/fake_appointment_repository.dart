import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeAppointmentRepository implements AppointmentRepository {
  final List<Appointment> _appointments = [];

  @override
  Future<List<Appointment>> getAll() async {
    final appointments = [..._appointments];

    appointments.sort((a, b) => a.date.value.compareTo(b.date.value));

    return List.unmodifiable(appointments);
  }

  @override
  Future<void> save(Appointment appointment) async {
    _appointments.add(appointment);
  }

  @override
  Future<void> update(Appointment appointment) async {
    final index = _appointments.indexWhere((item) => item.id == appointment.id);

    if (index == -1) return;

    _appointments[index] = appointment;
  }

  @override
  Future<void> delete(String id) async {
    _appointments.removeWhere((item) => item.id == id);
  }
}
