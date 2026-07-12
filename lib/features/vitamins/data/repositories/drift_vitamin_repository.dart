import '../../domain/entities/vitamin.dart';
import '../../domain/repositories/vitamin_repository.dart';
import '../datasources/drift_vitamin_local_datasource.dart';
import '../dtos/vitamin_dto.dart';

class DriftVitaminRepository implements VitaminRepository {
  const DriftVitaminRepository(this._local);
  final Future<DriftVitaminLocalDatasource> Function() _local;
  @override
  Future<List<Vitamin>> getAll() async =>
      (await (await _local()).getAll()).map((v) => v.toEntity()).toList();
  @override
  Future<void> save(Vitamin value) async =>
      (await _local()).save(VitaminDto.fromEntity(value, now: DateTime.now()));
  @override
  Future<void> update(Vitamin value) => save(value);
  @override
  Future<void> delete(String id) async => (await _local()).delete(id);
}
