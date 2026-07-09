import 'dart:convert';

import '../services/local_storage_service.dart';
import 'local_database.dart';
import 'local_database_record.dart';

class SharedPreferencesLocalDatabase implements LocalDatabase {
  const SharedPreferencesLocalDatabase(this._storage);

  static const _prefix = 'local_database.collection';

  final LocalStorageService _storage;

  @override
  Future<List<LocalDatabaseRecord>> getAll(String collection) async {
    return _readCollection(collection);
  }

  @override
  Future<LocalDatabaseRecord?> getById(String collection, String id) async {
    final records = _readCollection(collection);

    for (final record in records) {
      if (record.id == id) return record;
    }

    return null;
  }

  @override
  Future<void> upsert(String collection, LocalDatabaseRecord record) async {
    final records = _readCollection(collection);
    final index = records.indexWhere((item) => item.id == record.id);

    if (index == -1) {
      records.add(record);
    } else {
      records[index] = record;
    }

    await _writeCollection(collection, records);
  }

  @override
  Future<void> delete(String collection, String id) async {
    final records = _readCollection(collection)
      ..removeWhere((record) => record.id == id);

    await _writeCollection(collection, records);
  }

  List<LocalDatabaseRecord> _readCollection(String collection) {
    final raw = _storage.getString(_key(collection));
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;

    return decoded
        .map(
          (item) => LocalDatabaseRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> _writeCollection(
    String collection,
    List<LocalDatabaseRecord> records,
  ) {
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );

    return _storage.setString(_key(collection), encoded);
  }

  String _key(String collection) => '$_prefix.$collection';
}
