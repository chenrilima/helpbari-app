import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Macro 2 migration is ownership-safe, immutable and rerunnable', () {
    final sql = File(
      'supabase/migrations/20260721000000_macro2_prescription_platform.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains('CREATE TABLE IF NOT EXISTS public.prescription_versions'),
    );
    expect(sql, contains('FOREIGN KEY (user_id,prescription_id)'));
    expect(
      sql,
      contains('FOREIGN KEY (user_id,prescription_id,prescription_item_id)'),
    );
    expect(sql, contains('REFERENCES public.smart_routines(user_id,id)'));
    expect(
      sql,
      contains('REFERENCES public.routine_plans(user_id,routine_id,id)'),
    );
    expect(sql, contains('ENABLE ROW LEVEL SECURITY'));
    expect(sql, contains('user_id = auth.uid()'));
    expect(sql, isNot(contains('FOR DELETE')));
    expect(sql, contains('NEW IS NOT DISTINCT FROM OLD'));
    expect(sql, contains('prescription_versions_no_update'));
    expect(sql, contains('prescription_reviews_no_update'));
    expect(sql, contains("SET search_path = ''"));
    expect(sql, contains("set_config('helpbari.lgpd_deletion','on',true)"));
    expect(sql, contains('DROP POLICY IF EXISTS'));
    expect(sql, contains('DROP TRIGGER IF EXISTS'));
  });
}
