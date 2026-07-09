import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_appointment_datasource.dart';
import '../dtos/appointment_dto.dart';

class LocalAppointmentRepository implements AppointmentRepository {
  const LocalAppointmentRepository(this._datasource);

  final LocalAppointmentDatasource _datasource;

  @override
  Future<List<Appointment>> getAll() async {
    final appointments = await _datasource.getAll();

    return appointments.map((appointment) => appointment.toEntity()).toList();
  }

  @override
  Future<void> save(Appointment appointment) {
    return _datasource.save(
      AppointmentDto.fromEntity(appointment, now: DateTime.now()),
    );
  }

  @override
  Future<void> update(Appointment appointment) {
    return _datasource.save(
      AppointmentDto.fromEntity(appointment, now: DateTime.now()),
    );
  }

  @override
  Future<void> delete(String id) {
    return _datasource.delete(id);
  }
}
