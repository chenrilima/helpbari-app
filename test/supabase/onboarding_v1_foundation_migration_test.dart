import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260722000000_onboarding_v1_foundation.sql',
  ).readAsStringSync();
  final sql = migration.toLowerCase();

  test('migration is additive and creates the versioned onboarding state', () {
    expect(
      sql,
      contains('create table if not exists public.onboarding_states'),
    );
    expect(sql, contains('onboarding_version integer'));
    expect(sql, contains('completed_step_ids jsonb'));
    expect(sql, contains('treatment_tracking_enabled'));
    expect(sql, contains('water_tracking_enabled'));
    expect(sql, contains('weight_tracking_enabled'));
    expect(sql, isNot(contains('drop table')));
  });

  test('onboarding state is user-isolated and covered by LGPD deletion', () {
    expect(sql, contains('auth.uid() = user_id'));
    expect(
      sql,
      contains(
        'delete from public.onboarding_states where user_id=current_user_id',
      ),
    );
    expect(sql, isNot(contains('for delete\n  on public.onboarding_states')));
  });
}
