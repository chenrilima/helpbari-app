import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'exam attachment migration is private owner scoped and supports delete',
    () {
      final sql = File(
        'supabase/migrations/20260713000000_exam_attachments_storage.sql',
      ).readAsStringSync();
      expect(sql, contains('exams_attachment_path_owner_check'));
      expect(sql, contains('exam-attachments delete own'));
      expect(sql, contains('FOR DELETE TO authenticated'));
      expect(sql, contains('application/pdf'));
      expect(sql, contains('file_size_limit'));
    },
  );
}
