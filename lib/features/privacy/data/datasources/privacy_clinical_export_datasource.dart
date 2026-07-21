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
      'onboardingState': await _rows('onboarding_state_records', userId),
      'documents': await _rows('document_input_records', userId),
      'documentProcessings': await _rows('document_processing_records', userId),
      'extractedDocumentFields': await _rows('extracted_field_records', userId),
      'bioimpedance': await _rows('bioimpedance_records', userId),
      'smartRoutines': await _rows('smart_routine_records', userId),
      'routinePlans': await _rows('routine_plan_records', userId),
      'routineSchedules': await _rows('routine_schedule_records', userId),
      'routinePauses': await _rows('routine_pause_records', userId),
      'routineOccurrences': await _rows('routine_occurrence_records', userId),
      'routineAdherenceEvents': await _rows(
        'routine_adherence_event_records',
        userId,
      ),
      'unifiedTreatmentMappings': await _rows(
        'unified_treatment_legacy_mappings',
        userId,
      ),
      'unifiedTreatmentLogMappings': await _rows(
        'unified_treatment_legacy_log_mappings',
        userId,
      ),
      'prescriptionVersions': await _rows(
        'prescription_version_records',
        userId,
      ),
      'prescriptionReviews': await _rows('prescription_review_records', userId),
      'treatmentProposals': await _rows('treatment_proposal_records', userId),
      'prescriptionRoutineLinks': await _rows(
        'prescription_routine_link_records',
        userId,
      ),
      'localNotificationOperations': <String, Object?>{},
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
