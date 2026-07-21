import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sync revision migration replaces device-clock LWW with server CAS', () {
    final migration = File(
      'supabase/migrations/20260724000000_sync_server_revisions.sql',
    ).readAsStringSync();

    expect(migration, contains('server_revision bigint NOT NULL DEFAULT 1'));
    expect(
      migration,
      contains('NEW.server_revision := OLD.server_revision + 1'),
    );
    expect(migration, contains('NEW.updated_at := clock_timestamp()'));
    expect(migration, contains('SECURITY INVOKER'));
    expect(
      migration,
      contains(
        'GRANT EXECUTE ON FUNCTION public.sync_server_now() TO authenticated',
      ),
    );
    expect(
      migration,
      contains('DROP TRIGGER IF EXISTS vitamins_latest_updated_at_wins'),
    );
  });
}
