import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Smart Routines is registered exactly once in the Sync Manager list',
    () {
      final source = File(
        'lib/core/sync/sync_providers.dart',
      ).readAsStringSync();
      expect(
        RegExp(r'SmartRoutinesSyncRepository\(').allMatches(source).length,
        1,
      );
      expect(source, contains('if (user == null || supabaseClient == null)'));
    },
  );
}
