import '../../domain/entities/medication_log.dart';
import '../../domain/repositories/medication_log_repository.dart';
import '../../domain/value_objects/medication_status.dart';
import '../datasources/drift_medication_log_local_datasource.dart';

class DriftMedicationLogRepository implements MedicationLogRepository {
  const DriftMedicationLogRepository(this._local);
  final Future<DriftMedicationLogLocalDatasource> Function() _local;
  @override
  Future<List<MedicationLog>> getByPeriod(DateTime start, DateTime end) async =>
      (await (await _local()).getByPeriod(
        start,
        end,
      )).map((v) => v.toEntity()).toList();
  @override
  Future<MedicationLog> setStatus({
    required String medicationId,
    required DateTime date,
    required MedicationStatus status,
  }) async => (await (await _local()).setStatus(
    medicationId: medicationId,
    date: date,
    status: status,
  )).toEntity();
  @override
  Future<void> deleteForMedication(String id) async =>
      (await _local()).deleteForMedication(id);
}
