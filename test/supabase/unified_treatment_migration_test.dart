import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unified treatment migration hardens plans, events, RLS and LGPD', () {
    final sql = File(
      'supabase/migrations/20260720030000_unified_treatment_engine.sql',
    ).readAsStringSync();
    expect(sql, contains("SET duration_type = 'bounded'"));
    expect(sql, contains('routine_plans_preserve_revision'));
    expect(sql, contains('routine_schedules_preserve_revision'));
    expect(sql, contains('immutable routine schedule revision'));
    expect(sql, contains('routine_adherence_events_no_update'));
    expect(sql, contains('unified_treatment_legacy_mappings'));
    expect(sql, contains('ENABLE ROW LEVEL SECURITY'));
    expect(sql, contains('DELETE FROM public.routine_adherence_events'));
    expect(sql, contains("set_config('helpbari.lgpd_deletion','on',true)"));
    expect(
      sql,
      contains("current_setting('helpbari.lgpd_deletion', true) = 'on'"),
    );
    expect(sql, contains('unified_treatment_remote_sync_enabled'));
  });
}
