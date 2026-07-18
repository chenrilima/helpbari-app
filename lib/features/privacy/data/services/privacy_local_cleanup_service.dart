import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/drift/app_database.dart';

class PrivacyLocalCleanupService {
  const PrivacyLocalCleanupService({
    required AppDatabase database,
    required SharedPreferences preferences,
  }) : _database = database,
       _preferences = preferences;

  final AppDatabase _database;
  final SharedPreferences _preferences;

  Future<void> clearUser(String userId) async {
    if (userId.isEmpty || userId == 'anonymous') {
      throw StateError('Invalid user for local privacy cleanup.');
    }
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
    'privacy_consent_records',
    'medication_log_records',
    'medication_records',
    'vitamin_log_records',
    'vitamin_records',
    'exam_records',
    'medical_exams',
    'medical_exam_results',
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
