import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/use_cases.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../meals/presentation/providers/meal_use_cases_provider.dart';
import '../../../medical_exams/presentation/providers/medical_exam_use_cases_provider.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../medical_prescriptions/presentation/providers/medical_prescription_providers.dart';
import '../../application/home_intelligence_query_facade.dart';
import '../../domain/models/home_intelligence_models.dart';

final healthDashboardUseCasesProvider = Provider<HealthDashboardUseCases>((
  ref,
) {
  return HealthDashboardUseCases(
    profile: ref.watch(profileUseCasesProvider),
    weight: ref.watch(weightUseCasesProvider),
    water: ref.watch(waterUseCasesProvider),
    meals: ref.watch(mealUseCasesProvider),
    appointments: ref.watch(appointmentUseCasesProvider),
    exams: ref.watch(medicalExamUseCasesProvider),
    settings: ref.watch(settingsUseCasesProvider),
    treatment: () => ref.read(treatmentAdherenceQueryServiceProvider.future),
  );
});

final homeIntelligenceQueryFacadeProvider =
    Provider<HomeIntelligenceQueryFacade>((ref) {
      final session = ref.watch(authSessionProvider);
      if (session == null) {
        throw StateError(
          'Authenticated user is required for Home Intelligence.',
        );
      }
      return HomeIntelligenceQueryFacade(
        userId: session.id,
        dashboard: ref.watch(healthDashboardUseCasesProvider),
        treatment: () =>
            ref.read(treatmentAdherenceQueryServiceProvider.future),
        appointments: ref.watch(appointmentUseCasesProvider),
        prescriptions: ref.watch(medicalPrescriptionUseCasesProvider),
        clock: ref.watch(clockServiceProvider),
        syncState: () => ref.read(syncManagerProvider),
        timeZone: () =>
            ref.read(notificationSchedulerProvider).state.timeZone ?? 'UTC',
      );
    });

final todayDashboardProvider = FutureProvider<TodayDashboardReadModel>((ref) {
  return ref.watch(homeIntelligenceQueryFacadeProvider).today();
});

final nextActionsProvider = Provider<AsyncValue<NextActionsReadModel>>(
  (ref) =>
      ref.watch(todayDashboardProvider).whenData((value) => value.nextActions),
);

final todayAgendaProvider = Provider<AsyncValue<AgendaReadModel>>(
  (ref) => ref.watch(todayDashboardProvider).whenData((value) => value.agenda),
);

final dailyProgressProvider = Provider<AsyncValue<ProgressSummaryReadModel>>(
  (ref) =>
      ref.watch(todayDashboardProvider).whenData((value) => value.progress),
);

final treatmentSummaryProvider =
    Provider<AsyncValue<TreatmentSummaryReadModel>>(
      (ref) => ref
          .watch(todayDashboardProvider)
          .whenData((value) => value.treatment),
    );

final homeInsightsProvider = Provider<AsyncValue<InsightFeedReadModel>>(
  (ref) =>
      ref.watch(todayDashboardProvider).whenData((value) => value.insights),
);

final quickActionsProvider = Provider<AsyncValue<QuickActionsReadModel>>(
  (ref) =>
      ref.watch(todayDashboardProvider).whenData((value) => value.quickActions),
);

final quickStatsProvider = Provider<AsyncValue<QuickStatsReadModel>>(
  (ref) =>
      ref.watch(todayDashboardProvider).whenData((value) => value.quickStats),
);

final homeSyncStatusProvider = Provider<SyncState>(
  (ref) => ref.watch(syncManagerProvider),
);

enum HomeProgressPeriod { week, month, quarter }

final progressTrendProvider =
    FutureProvider.family<ProgressTrendReadModel, HomeProgressPeriod>((
      ref,
      period,
    ) async {
      final days = switch (period) {
        HomeProgressPeriod.week => 7,
        HomeProgressPeriod.month => 30,
        HomeProgressPeriod.quarter => 90,
      };
      return ref.watch(homeIntelligenceQueryFacadeProvider).weightTrend(days);
    });
