import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacy migration is owner scoped and deletion covers all buckets', () {
    final sql = File(
      'supabase/migrations/20260716000000_privacy_and_data.sql',
    ).readAsStringSync();
    final storageSql = [
      sql,
      File(
        'supabase/migrations/20260712000000_profile_photo_storage.sql',
      ).readAsStringSync(),
      File(
        'supabase/migrations/20260713000000_exam_attachments_storage.sql',
      ).readAsStringSync(),
    ].join('\n');

    expect(sql, contains('CREATE TABLE public.privacy_consents'));
    expect(sql, contains('user_id = auth.uid()'));
    expect(sql, contains('SECURITY DEFINER'));
    expect(sql, contains('SET search_path'));
    expect(storageSql, contains("'profile-photos'"));
    expect(storageSql, contains("'exam-attachments'"));
    expect(storageSql, contains("'medical-reports'"));
    expect(storageSql, contains("'report-attachments'"));
    expect(sql, contains('medical-reports delete own'));
    expect(sql, contains('report-attachments delete own'));
    expect(sql, contains('DELETE FROM auth.users'));
    expect(sql, contains('REVOKE ALL'));
    expect(sql, contains('GRANT EXECUTE'));
  });
}
