import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/privacy/data/datasources/privacy_supabase_datasource.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260720000000_complete_privacy_deletion.sql';

  test('migration covers every current user-owned public table', () async {
    final sql = await File(migrationPath).readAsString();
    const tables = <String>[
      'medical_prescription_items',
      'medical_exam_results',
      'medical_prescriptions',
      'medical_exams',
      'bioimpedance_records',
      'extracted_document_fields',
      'document_processings',
      'document_inputs',
      'report_attachments',
      'medical_reports',
      'medication_logs',
      'vitamin_logs',
      'notification_reminders',
      'appointments',
      'exams',
      'meals',
      'medications',
      'vitamins',
      'water_records',
      'weight_records',
      'settings',
      'profiles',
      'privacy_consents',
      'privacy_deletion_requests',
    ];

    for (final table in tables) {
      expect(sql, contains('DELETE FROM public.$table'));
    }
    expect(sql, contains('current_user_id uuid := auth.uid()'));
    expect(sql, contains("SET search_path = ''"));
    expect(sql, contains('GRANT EXECUTE ON FUNCTION public.delete_my_data()'));
    expect(sql, isNot(contains('DELETE FROM storage.objects')));
  });

  test('children are deleted before parents', () async {
    final sql = await File(migrationPath).readAsString();
    expect(
      sql.indexOf('DELETE FROM public.medical_prescription_items'),
      lessThan(sql.indexOf('DELETE FROM public.medical_prescriptions')),
    );
    expect(
      sql.indexOf('DELETE FROM public.medical_exam_results'),
      lessThan(sql.indexOf('DELETE FROM public.medical_exams')),
    );
    expect(
      sql.indexOf('DELETE FROM public.medical_exams'),
      lessThan(sql.indexOf('DELETE FROM public.document_inputs')),
    );
  });

  test('all private Storage buckets are included in the API cleanup', () {
    expect(
      privacyStorageBuckets,
      containsAll(<String>[
        'profile-photos',
        'exam-attachments',
        'medical-reports',
        'report-attachments',
        'clinical-documents',
      ]),
    );
  });
}
