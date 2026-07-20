import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/drift/app_database.dart';
import 'privacy_local_file_cleanup_service.dart';

class PrivacyLocalCleanupService {
  const PrivacyLocalCleanupService({
    required AppDatabase database,
    required SharedPreferences preferences,
    this.fileCleanup = const PrivacyLocalFileCleanupService(),
  }) : _database = database,
       _preferences = preferences;

  final AppDatabase _database;
  final SharedPreferences _preferences;
  final PrivacyLocalFileCleanupService fileCleanup;

  Future<void> clearUser(String userId) async {
    if (userId.isEmpty || userId == 'anonymous') {
      throw StateError('Invalid user for local privacy cleanup.');
    }
    await fileCleanup.clearKnownFiles(await _knownLocalPaths(userId));
    await _database.transaction(() async {
      for (final table in _userTables) {
        await _database.customUpdate(
          'DELETE FROM $table WHERE user_id = ?',
          variables: [Variable<String>(userId)],
          updates: const {},
        );
      }
    });
    await _clearPreferences(userId);
  }

  Future<List<String?>> _knownLocalPaths(String userId) async {
    final documents = await (_database.select(
      _database.documentInputRecords,
    )..where((row) => row.userId.equals(userId))).get();
    final legacyExams = await (_database.select(
      _database.examRecords,
    )..where((row) => row.userId.equals(userId))).get();
    final medicalExams = await (_database.select(
      _database.medicalExams,
    )..where((row) => row.userId.equals(userId))).get();
    return <String?>[
      ...documents.map((row) => row.localPath),
      ...legacyExams.map((row) => row.attachmentPath),
      ...medicalExams.map((row) => row.legacyAttachmentPath),
    ];
  }

  Future<void> _clearPreferences(String userId) async {
    for (final key in _preferences.getKeys().toList()) {
      if (_isUserScopedKey(key, userId) || key == _onboardingDraftKey) {
        await _preferences.remove(key);
        continue;
      }
      final stored = _preferences.get(key);
      if (stored is! String || stored.isEmpty) continue;
      final raw = stored;
      if (key == 'core.sync.state') {
        if (_jsonUserId(raw) == userId) await _preferences.remove(key);
        continue;
      }
      if (key.startsWith('local_database.collection.')) {
        await _filterLegacyCollection(key, raw, userId);
      }
    }
  }

  Future<void> _filterLegacyCollection(
    String key,
    String raw,
    String userId,
  ) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final retained = decoded.where((item) {
        if (item is! Map) return true;
        final map = Map<String, dynamic>.from(item);
        final metadata = map['metadata'];
        if (metadata is! Map) return true;
        final values = Map<String, dynamic>.from(metadata);
        return values['userId'] != userId && values['id'] != userId;
      }).toList();
      await _preferences.setString(key, jsonEncode(retained));
    } on FormatException {
      // Unknown legacy values are preserved instead of deleting another user.
    }
  }

  String? _jsonUserId(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded['userId'] as String? : null;
    } on FormatException {
      return null;
    }
  }

  bool _isUserScopedKey(String key, String userId) =>
      key.contains('.$userId.') || key.endsWith('.$userId');

  static const _onboardingDraftKey = 'onboarding.profileDraft.v1';
  static const _userTables = <String>[
    'unified_treatment_legacy_log_mappings',
    'unified_treatment_legacy_mappings',
    'unified_treatment_cutover_states',
    'routine_adherence_event_records',
    'routine_occurrence_records',
    'routine_pause_records',
    'routine_schedule_records',
    'routine_plan_records',
    'smart_routine_records',
    'medical_prescription_item_records',
    'medical_exam_results',
    'medical_prescription_records',
    'medical_exams',
    'bioimpedance_records',
    'extracted_field_records',
    'document_processing_records',
    'document_input_records',
    'privacy_consent_records',
    'medication_log_records',
    'medication_records',
    'vitamin_log_records',
    'vitamin_records',
    'exam_records',
    'appointment_records',
    'meal_records',
    'weight_records',
    'water_records',
    'settings_records',
    'profile_records',
    'sync_cursors',
    'medication_cutovers',
    'vitamin_cutovers',
    'exam_cutovers',
    'appointment_cutovers',
    'meal_cutovers',
    'weight_cutovers',
    'settings_cutovers',
    'profile_cutovers',
    'water_cutovers',
  ];
}
