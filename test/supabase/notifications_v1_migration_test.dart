import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/20260723000000_notifications_v1.sql',
  ).readAsStringSync().toLowerCase();

  test('adds synchronized preferences and preserves legacy booleans', () {
    expect(sql, contains('add column if not exists notification_preferences'));
    expect(
      sql,
      contains('vitamin_reminders_enabled or medication_reminders_enabled'),
    );
    expect(sql, contains("'water', false"));
    expect(sql, contains("'meals', false"));
    expect(sql, contains("'weight', false"));
    expect(sql, isNot(contains('drop table')));
  });

  test('does not synchronize local permission, manifest or plugin ids', () {
    expect(sql, isNot(contains('plugin_id')));
    expect(sql, isNot(contains('permission_state')));
    expect(sql, isNot(contains('notification_manifest')));
  });
}
