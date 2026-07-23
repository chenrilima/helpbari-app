import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap never asks for notification permission automatically', () {
    final bootstrap = File(
      'lib/app/bootstrap/notification_bootstrap_provider.dart',
    ).readAsStringSync();
    expect(bootstrap, isNot(contains('requestPermissions(')));
  });

  test('concrete scheduler checks permission without requesting it', () {
    final service = File(
      'lib/core/services/notifications/app_local_notification_service.dart',
    ).readAsStringSync();
    final scheduleBody = service.substring(
      service.indexOf('Future<void> _schedule'),
    );
    expect(scheduleBody, contains('permissionState()'));
    expect(scheduleBody, isNot(contains('requestPermissions()')));
  });

  test('onboarding requests permission only in the affirmative handler', () {
    final page = File(
      'lib/features/onboarding/presentation/pages/onboarding_page.dart',
    ).readAsStringSync();
    expect(page, contains('if (value)'));
    expect(page, contains('requestPermissions()'));
  });
}
