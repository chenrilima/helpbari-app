import 'local_database_record.dart';

abstract interface class LocalDatabase {
  Future<List<LocalDatabaseRecord>> getAll(String collection);

  Future<LocalDatabaseRecord?> getById(String collection, String id);

  Future<void> upsert(String collection, LocalDatabaseRecord record);

  Future<void> delete(String collection, String id);
}
