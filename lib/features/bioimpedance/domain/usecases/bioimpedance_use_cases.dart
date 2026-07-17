import '../entities/bioimpedance_record.dart';
import '../repositories/bioimpedance_repository.dart';

class BioimpedanceUseCases {
  const BioimpedanceUseCases(this._repository);

  final BioimpedanceRepository _repository;

  Future<List<BioimpedanceRecord>> getHistory() => _repository.getHistory();
  Future<BioimpedanceRecord?> getById(String id) => _repository.getById(id);
  Future<void> save(BioimpedanceRecord record) => _repository.save(record);
  Future<void> delete(String id) => _repository.delete(id);
}
