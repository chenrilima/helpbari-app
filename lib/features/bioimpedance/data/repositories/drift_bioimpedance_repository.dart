import '../../domain/entities/bioimpedance_record.dart';
import '../../domain/repositories/bioimpedance_repository.dart';
import '../datasources/drift_bioimpedance_local_datasource.dart';

class DriftBioimpedanceRepository implements BioimpedanceRepository {
  const DriftBioimpedanceRepository(this._local);

  final Future<DriftBioimpedanceLocalDatasource> Function() _local;

  @override
  Future<List<BioimpedanceRecord>> getHistory() async =>
      (await _local()).getHistory();

  @override
  Future<BioimpedanceRecord?> getById(String id) async =>
      (await _local()).getById(id);

  @override
  Future<void> save(BioimpedanceRecord record) async =>
      (await _local()).save(record);

  @override
  Future<void> delete(String id) async => (await _local()).delete(id);
}
