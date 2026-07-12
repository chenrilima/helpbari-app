import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/features/privacy/data/services/privacy_local_cleanup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboarding.user.v2.user-a.completed': true,
      'onboarding.user.v2.user-b.completed': true,
      'onboarding.profileDraft.v1': '{"name":"Sensitive"}',
      'core.sync.state': jsonEncode({'userId': 'user-a'}),
      'local_database.collection.water_records': jsonEncode([
        _legacy('one', 'user-a'),
        _legacy('two', 'user-b'),
      ]),
    });
    preferences = await SharedPreferences.getInstance();
    database = AppDatabase(NativeDatabase.memory());
    await database.customInsert(
      "INSERT INTO privacy_consent_records "
      "(id,user_id,terms_version,privacy_version,accepted_at,device_id,timezone,created_at,updated_at,sync_status,sync_attempts) "
      "VALUES ('a','user-a','1','1',0,'d','UTC',0,0,'synced',0),"
      "('b','user-b','1','1',0,'d','UTC',0,0,'synced',0)",
    );
  });

  tearDown(() => database.close());

  test('clears Drift and SharedPreferences only for selected user', () async {
    await PrivacyLocalCleanupService(
      database: database,
      preferences: preferences,
    ).clearUser('user-a');

    final rows = await database.select(database.privacyConsentRecords).get();
    expect(rows.map((row) => row.userId), ['user-b']);
    expect(
      preferences.containsKey('onboarding.user.v2.user-a.completed'),
      isFalse,
    );
    expect(preferences.getBool('onboarding.user.v2.user-b.completed'), isTrue);
    expect(preferences.containsKey('onboarding.profileDraft.v1'), isFalse);
    expect(preferences.containsKey('core.sync.state'), isFalse);
    final legacy =
        jsonDecode(
              preferences.getString('local_database.collection.water_records')!,
            )
            as List;
    expect(legacy, hasLength(1));
    expect((legacy.single as Map)['metadata']['userId'], 'user-b');
  });
}

Map<String, Object?> _legacy(String id, String userId) => {
  'metadata': {
    'id': id,
    'userId': userId,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'deletedAt': null,
    'syncStatus': 'synced',
  },
  'data': <String, Object?>{},
};
