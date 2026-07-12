import '../entities/entities.dart';
import '../repositories/repositories.dart';
import '../value_objects/value_objects.dart';

class VitaminUseCases {
  const VitaminUseCases(this._repository, [this._logs]);

  final VitaminRepository _repository;
  final VitaminLogRepository? _logs;

  Future<List<Vitamin>> getAll() {
    return _repository.getAll();
  }

  Future<void> save(Vitamin vitamin) {
    return _repository.save(vitamin);
  }

  Future<void> update(Vitamin vitamin) {
    return _repository.update(vitamin);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<List<VitaminLog>> getLogs(DateTime start, DateTime end) =>
      _logs?.getByPeriod(start, end) ?? Future.value(const []);

  Future<int> getPendingCount({DateTime? date}) async {
    final vitamins = await _repository.getAll();
    final day = _day(date ?? DateTime.now());
    final logs = await getLogs(day, day);
    final completed = logs
        .where((log) => log.status != VitaminStatus.pending)
        .map((log) => log.vitaminId)
        .toSet();
    return vitamins.where((vitamin) => !completed.contains(vitamin.id)).length;
  }

  Future<void> markAsTaken(String id) async {
    await setDailyStatus(id, VitaminStatus.taken);
  }

  Future<void> markAsSkipped(String id) async {
    await setDailyStatus(id, VitaminStatus.skipped);
  }

  Future<void> resetStatus(String id) async {
    await setDailyStatus(id, VitaminStatus.pending);
  }

  Future<VitaminLog> setDailyStatus(
    String id,
    VitaminStatus status, {
    DateTime? date,
  }) => _logs == null
      ? Future.error(StateError('Histórico diário indisponível.'))
      : _logs.setStatus(
          vitaminId: id,
          date: _day(date ?? DateTime.now()),
          status: status,
        );

  Future<double> adherence(DateTime start, DateTime end) async {
    final logs = await getLogs(_day(start), _day(end));
    final resolved = logs
        .where((log) => log.status != VitaminStatus.pending)
        .toList();
    if (resolved.isEmpty) return 0;
    return resolved.where((log) => log.status == VitaminStatus.taken).length /
        resolved.length *
        100;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
