import '../../domain/entities/vitamin_log.dart';
import '../../domain/repositories/vitamin_log_repository.dart';
import '../../domain/value_objects/vitamin_status.dart';
import '../datasources/drift_vitamin_log_local_datasource.dart';

class DriftVitaminLogRepository implements VitaminLogRepository {
  const DriftVitaminLogRepository(this._local);
  final Future<DriftVitaminLogLocalDatasource> Function() _local;
  @override
  Future<List<VitaminLog>> getByPeriod(DateTime start, DateTime end) async =>
      (await (await _local()).getByPeriod(
        start,
        end,
      )).map((v) => v.toEntity()).toList();
  @override
  Future<VitaminLog> setStatus({
    required String vitaminId,
    required DateTime date,
    required VitaminStatus status,
  }) async => (await (await _local()).setStatus(
    vitaminId: vitaminId,
    date: date,
    status: status,
  )).toEntity();
  @override
  Future<void> deleteForVitamin(String id) async =>
      (await _local()).deleteForVitamin(id);
}
