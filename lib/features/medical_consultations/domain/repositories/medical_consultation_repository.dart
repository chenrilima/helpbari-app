import '../entities/entities.dart';

abstract interface class MedicalConsultationRepository {
  Future<List<MedicalConsultation>> getHistory();
  Future<MedicalConsultation?> getById(String id);
  Future<MedicalConsultation?> getByAppointmentId(String appointmentId);
  Future<void> save(MedicalConsultation consultation);
  Future<void> delete(String id);
}
