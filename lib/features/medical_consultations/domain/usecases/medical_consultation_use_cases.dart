import '../../../appointments/domain/entities/entities.dart';
import '../../../../core/sync/sync.dart';
import '../entities/entities.dart';
import '../repositories/medical_consultation_repository.dart';

class MedicalConsultationUseCases {
  const MedicalConsultationUseCases(this._repository);

  final MedicalConsultationRepository _repository;

  Future<List<MedicalConsultation>> getHistory() => _repository.getHistory();
  Future<MedicalConsultation?> getById(String id) => _repository.getById(id);
  Future<MedicalConsultation?> getByAppointmentId(String appointmentId) =>
      _repository.getByAppointmentId(appointmentId);
  Future<void> save(MedicalConsultation consultation) =>
      _repository.save(consultation);
  Future<void> delete(String id) => _repository.delete(id);

  MedicalConsultation draftFromAppointment({
    required Appointment appointment,
    required String id,
    required String userId,
    required DateTime now,
  }) => MedicalConsultation(
    id: id,
    userId: userId,
    consultationAt: appointment.date.value,
    title: appointment.title,
    professionalName: appointment.doctorName,
    location: appointment.location,
    appointmentId: appointment.id,
    source: MedicalConsultationSource.appointment,
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatus.pendingCreate,
  );
}
