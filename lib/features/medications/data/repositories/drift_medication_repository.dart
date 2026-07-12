import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/drift_medication_local_datasource.dart';
import '../dtos/medication_dto.dart';

class DriftMedicationRepository implements MedicationRepository {
  const DriftMedicationRepository(this._local);
  final Future<DriftMedicationLocalDatasource> Function() _local;
  @override
  Future<List<Medication>> getAll() async =>
      (await (await _local()).getAll()).map((v) => v.toEntity()).toList();
  @override
  Future<void> save(Medication v) async =>
      (await _local()).save(MedicationDto.fromEntity(v, now: DateTime.now()));
  @override
  Future<void> update(Medication v) => save(v);
  @override
  Future<void> delete(String id) async => (await _local()).delete(id);
}
