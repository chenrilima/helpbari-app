import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync_result.dart';
import 'package:helpbari/features/home/application/home_sync_invalidation_policy.dart';

void main() {
  const policy = HomeSyncInvalidationPolicy();

  test('water refreshes hydration projections but not agenda', () {
    final areas = policy.areasFor({SyncDomain.water});

    expect(areas, contains(HomeRefreshArea.healthSource));
    expect(areas, contains(HomeRefreshArea.progress));
    expect(areas, isNot(contains(HomeRefreshArea.agenda)));
    expect(areas, isNot(contains(HomeRefreshArea.prescriptionSource)));
  });

  test('weight does not refresh prescriptions or appointments', () {
    final areas = policy.areasFor({SyncDomain.weight});

    expect(areas, contains(HomeRefreshArea.progress));
    expect(areas, isNot(contains(HomeRefreshArea.prescriptionSource)));
    expect(areas, isNot(contains(HomeRefreshArea.appointmentSource)));
  });

  test('prescriptions do not refresh hydration source', () {
    final areas = policy.areasFor({SyncDomain.prescriptions});

    expect(areas, contains(HomeRefreshArea.nextActions));
    expect(areas, contains(HomeRefreshArea.insights));
    expect(areas, isNot(contains(HomeRefreshArea.healthSource)));
  });
}
