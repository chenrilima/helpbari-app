import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Macro 2 sync keeps parent order and inclusive tied cursor', () {
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
    expect(source, contains('request.gte('));
    expect(source, isNot(contains('request.gt(')));
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
}
