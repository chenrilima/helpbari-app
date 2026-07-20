import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';

class PrivacyClinicalExportDatasource {
  const PrivacyClinicalExportDatasource(this._database);

  final AppDatabase _database;

  Future<Map<String, Object?>> load(String userId) async {
    if (userId.isEmpty || userId == 'anonymous') {
      throw StateError('Authenticated user required for clinical export.');
    }

    return <String, Object?>{
      'documents': await _rows('document_input_records', userId),
      'documentProcessings': await _rows('document_processing_records', userId),
      'extractedDocumentFields': await _rows('extracted_field_records', userId),
      'bioimpedance': await _rows('bioimpedance_records', userId),
    };
  }

  Future<List<Map<String, Object?>>> _rows(String table, String userId) async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM $table WHERE user_id = ?',
          variables: [Variable<String>(userId)],
        )
        .get();
    return rows
        .map(
          (row) => row.data.map(
            (key, value) => MapEntry<String, Object?>(key, _jsonValue(value)),
          ),
        )
        .toList(growable: false);
  }

  Object? _jsonValue(Object? value) => switch (value) {
    DateTime date => date.toUtc().toIso8601String(),
    _ => value,
  };
}
