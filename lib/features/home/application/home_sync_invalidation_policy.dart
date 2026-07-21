import '../../../core/sync/sync_result.dart';

enum HomeRefreshArea {
  healthSource,
  treatmentSource,
  appointmentSource,
  prescriptionSource,
  agenda,
  treatment,
  progress,
  nextActions,
  insights,
  dashboard,
}

class HomeSyncInvalidationPolicy {
  const HomeSyncInvalidationPolicy();

  Set<HomeRefreshArea> areasFor(Set<SyncDomain> domains) {
    final areas = <HomeRefreshArea>{};
    for (final domain in domains) {
      areas.addAll(switch (domain) {
        SyncDomain.water || SyncDomain.weight || SyncDomain.meals => const {
          HomeRefreshArea.healthSource,
          HomeRefreshArea.progress,
          HomeRefreshArea.insights,
          HomeRefreshArea.dashboard,
        },
        SyncDomain.appointments => const {
          HomeRefreshArea.appointmentSource,
          HomeRefreshArea.agenda,
          HomeRefreshArea.nextActions,
          HomeRefreshArea.dashboard,
        },
        SyncDomain.treatment => const {
          HomeRefreshArea.treatmentSource,
          HomeRefreshArea.treatment,
          HomeRefreshArea.agenda,
          HomeRefreshArea.nextActions,
          HomeRefreshArea.progress,
          HomeRefreshArea.insights,
          HomeRefreshArea.dashboard,
        },
        SyncDomain.prescriptions => const {
          HomeRefreshArea.prescriptionSource,
          HomeRefreshArea.nextActions,
          HomeRefreshArea.insights,
          HomeRefreshArea.dashboard,
        },
        SyncDomain.settings || SyncDomain.profile => const {
          HomeRefreshArea.healthSource,
          HomeRefreshArea.progress,
          HomeRefreshArea.insights,
          HomeRefreshArea.dashboard,
        },
        _ => const <HomeRefreshArea>{},
      });
    }
    return Set.unmodifiable(areas);
  }
}
