import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'medical prescriptions migration enforces ownership and parent relation',
    () {
      final sql = File(
        'supabase/migrations/20260719000000_medical_prescriptions.sql',
      ).readAsStringSync();
      expect(sql, contains('CREATE TABLE public.medical_prescriptions'));
      expect(sql, contains('CREATE TABLE public.medical_prescription_items'));
      expect(sql, contains('FOREIGN KEY (user_id, prescription_id)'));
      expect(sql, contains('FOREIGN KEY (user_id, source_document_id)'));
      expect(sql, contains('user_id = auth.uid()'));
      expect(sql, contains('ENABLE ROW LEVEL SECURITY'));
      expect(sql, isNot(contains('FOR DELETE')));
      expect(sql, contains('linked_medication_id uuid'));
      expect(sql, contains('linked_vitamin_id uuid'));
    },
  );
}
