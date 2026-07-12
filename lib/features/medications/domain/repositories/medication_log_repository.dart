import '../entities/medication_log.dart';
import '../value_objects/medication_status.dart';

abstract interface class MedicationLogRepository {
  Future<List<MedicationLog>> getByPeriod(DateTime start, DateTime end);
  Future<MedicationLog> setStatus({
    required String medicationId,
    required DateTime date,
    required MedicationStatus status,
  });
  Future<void> deleteForMedication(String medicationId);
}
