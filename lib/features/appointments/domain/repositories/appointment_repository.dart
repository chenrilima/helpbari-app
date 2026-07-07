import '../entities/entities.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> getAll();

  Future<void> save(Appointment appointment);

  Future<void> update(Appointment appointment);

  Future<void> delete(String id);
}
