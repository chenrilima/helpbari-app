import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const legacyTable = 'notification_reminders';

  test('legacy reminder table has no Dart integration', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains(legacyTable)),
        reason: '${file.path} must not integrate the deprecated remote table.',
      );
    }
  });

  test('schema deprecation is non-destructive and preserves LGPD deletion', () {
    final migration = File(
      'supabase/migrations/20260720010000_deprecate_notification_reminders.sql',
    ).readAsStringSync();
    final deletion = File(
      'supabase/migrations/20260720000000_complete_privacy_deletion.sql',
    ).readAsStringSync();

    expect(migration, contains('COMMENT ON TABLE public.$legacyTable'));
    expect(migration, isNot(contains('DROP TABLE')));
    expect(migration, isNot(contains('DELETE FROM')));
    expect(deletion, contains('DELETE FROM public.$legacyTable'));
  });

  test('architecture documents local projections and future ownership', () {
    final architecture = File('docs/ARCHITECTURE.md').readAsStringSync();

    expect(architecture, contains('opção C'));
    expect(architecture, contains('projeções locais'));
    expect(architecture, contains('RoutineSchedule'));
    expect(architecture, contains('delete_my_data()'));
  });
}
