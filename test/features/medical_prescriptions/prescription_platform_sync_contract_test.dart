import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Macro 2 sync keeps parent order and delegates keyset pagination', () {
    final source = File(
      'lib/features/medical_prescriptions/data/repositories/'
      'prescription_platform_sync_repository.dart',
    ).readAsStringSync();

    expect(
      source.indexOf("'prescription_versions'"),
      lessThan(source.indexOf("'prescription_reviews'")),
    );
    expect(
      source.indexOf("'prescription_reviews'"),
      lessThan(source.indexOf("'treatment_proposals'")),
    );
    expect(source, contains('remote.pullUpdatedPages('));
    expect(source, contains('pageSize: pageSize'));
    expect(source, contains('if (await _dependenciesSynced(table, row.data))'));
  });

  test('platform sync runs after repositories referenced by foreign keys', () {
    final source = File('lib/core/sync/sync_providers.dart').readAsStringSync();

    expect(
      source.indexOf('DocumentProcessingSyncRepository('),
      lessThan(source.indexOf('PrescriptionPlatformSyncRepository(')),
    );
    expect(
      source.indexOf('SmartRoutinesSyncRepository('),
      lessThan(source.indexOf('PrescriptionPlatformSyncRepository(')),
    );
  });

  test('unified treatment remote sync is enabled without an async gap', () {
    final database = File(
      'lib/core/database/drift/app_database.dart',
    ).readAsStringSync();
    final providers = File(
      'lib/core/sync/sync_providers.dart',
    ).readAsStringSync();

    expect(database, contains("'unified_treatment_remote_sync_enabled': true"));
    expect(
      providers,
      isNot(contains('unifiedTreatmentRemoteSyncEnabledProvider')),
    );
    expect(providers, contains('SmartRoutinesSyncRepository('));
  });
}
