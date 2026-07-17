import '../entities/bioimpedance_record.dart';

abstract interface class BioimpedanceRepository {
  Future<List<BioimpedanceRecord>> getHistory();
  Future<BioimpedanceRecord?> getById(String id);
  Future<void> save(BioimpedanceRecord record);
  Future<void> delete(String id);
}
