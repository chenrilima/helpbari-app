import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile photo migration keeps storage private and owner-scoped', () {
    final sql = File(
      'supabase/migrations/20260712000000_profile_photo_storage.sql',
    ).readAsStringSync();
    expect(sql, contains('ADD COLUMN IF NOT EXISTS "photo_storage_path"'));
    expect(sql, contains('"public" = false'));
    expect(sql, contains('"file_size_limit" = 5242880'));
    expect(sql, contains("'image/jpeg', 'image/png', 'image/webp'"));
    expect(sql, contains('FOR DELETE TO authenticated'));
    expect(sql, contains("[2] = 'profile'"));
    expect(sql, contains('profiles_photo_storage_path_owner_check'));
  });
}
