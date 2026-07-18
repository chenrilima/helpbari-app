import '../../domain/entities/entities.dart';
import '../../domain/repositories/medical_consultation_repository.dart';
import '../datasources/drift_medical_consultation_local_datasource.dart';

class DriftMedicalConsultationRepository
    implements MedicalConsultationRepository {
  const DriftMedicalConsultationRepository(this._local);

  final Future<DriftMedicalConsultationLocalDatasource> Function() _local;

  @override
  Future<List<MedicalConsultation>> getHistory() async =>
      (await _local()).getHistory();

  @override
  Future<MedicalConsultation?> getById(String id) async =>
      (await _local()).getById(id);

  @override
  Future<MedicalConsultation?> getByAppointmentId(String appointmentId) async =>
      (await _local()).getByAppointmentId(appointmentId);

  @override
  Future<void> save(MedicalConsultation consultation) async =>
      (await _local()).save(consultation);

  @override
  Future<void> delete(String id) async => (await _local()).delete(id);
}
