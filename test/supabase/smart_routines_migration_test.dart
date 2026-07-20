import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/20260720020000_smart_routines.sql',
  ).readAsStringSync();

  test('creates six owner-scoped tables and composite foreign keys', () {
    for (final table in [
      'smart_routines',
      'routine_plans',
      'routine_schedules',
      'routine_pauses',
      'routine_occurrences',
      'routine_adherence_events',
    ]) {
      expect(sql, contains('CREATE TABLE public.$table'));
      expect(sql, contains("'$table'"));
    }
    expect(RegExp('ENABLE ROW LEVEL SECURITY').allMatches(sql), isNotEmpty);
    expect(sql, contains('FOREIGN KEY (user_id,occurrence_id)'));
    expect(sql, contains('FOREIGN KEY (user_id,plan_id)'));
    expect(sql, contains('FOREIGN KEY (user_id,schedule_id)'));
    expect(sql, contains('user_id = auth.uid()'));
  });

  test('events are insert-only and occurrences preserve original identity', () {
    expect(sql, contains('routine_adherence_events_no_update'));
    expect(sql, contains('routine_adherence_events_no_delete'));
    expect(
      sql,
      contains('GRANT SELECT,INSERT ON public.routine_adherence_events'),
    );
    expect(sql, isNot(contains('routine_adherence_events_update_own')));
    expect(sql, contains('routine_occurrences_preserve_identity'));
    expect(sql, contains('original_scheduled_for'));
    expect(sql, contains('routine_adherence_events_cursor_idx'));
  });
}
