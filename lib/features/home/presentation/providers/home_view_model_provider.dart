import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/health/calculators/protein_calculator.dart';
import '../../domain/usecases/use_cases.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../meals/presentation/providers/meal_use_cases_provider.dart';
import '../../../medical_exams/presentation/providers/medical_exam_use_cases_provider.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../settings/domain/entities/setting.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../medical_prescriptions/presentation/providers/medical_prescription_providers.dart';
import '../../application/home_intelligence_query_facade.dart';
import '../../application/home_runtime_guard.dart';
import '../../domain/models/home_intelligence_models.dart';
import '../../domain/models/health_dashboard_aggregate.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../smart_routines/domain/services/treatment_query_models.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';

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
        weight: ref.watch(weightUseCasesProvider),
        clock: ref.watch(clockServiceProvider),
        syncState: () => ref.read(syncManagerProvider),
        timeZone: () =>
            ref.read(notificationSchedulerProvider).state.timeZone ?? 'UTC',
      );
    });

final homeClinicalNowProvider = Provider<DateTime>(
  (ref) => ref.watch(clockServiceProvider).now(),
);

final _homeRequestContextProvider = Provider<_HomeRequestContext>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) throw StateError('Authenticated user is required.');
  final now = ref.watch(homeClinicalNowProvider);
  final sync = ref.watch(syncManagerProvider);
  final lastSyncAt = sync.lastSyncAt;
  return _HomeRequestContext(
    userId: session.id,
    now: now,
    date: DateTime(now.year, now.month, now.day),
    end: DateTime(now.year, now.month, now.day + 7),
    freshness: FreshnessReadModel(
      generatedAt: now,
      sourceUpdatedAt: lastSyncAt,
      isStale: lastSyncAt != null && now.difference(lastSyncAt).inHours >= 24,
      reason: lastSyncAt == null ? 'Ainda não sincronizado' : null,
    ),
    pendingSync:
        sync.phase == SyncPhase.partialFailure ||
        sync.phase == SyncPhase.failure,
  );
});

final homeHealthBaseSourceProvider = FutureProvider<HealthDashboardAggregate?>((
  ref,
) async {
  final context = ref.watch(_homeRequestContextProvider);
  return ref
      .watch(healthDashboardUseCasesProvider)
      .load(
        start: context.date,
        end: context.date,
        treatmentDaysOverride: {
          _dateKey(context.date): _emptyTreatmentDay(context.date),
        },
      );
});

final homeHealthSourceProvider = FutureProvider<HealthDashboardAggregate?>((
  ref,
) async {
  final values = await Future.wait<Object?>([
    ref.watch(homeHealthBaseSourceProvider.future),
    ref.watch(homeTreatmentSourceProvider.future),
  ]);
  final aggregate = values[0] as HealthDashboardAggregate?;
  if (aggregate == null) return null;
  return ref
      .watch(healthDashboardUseCasesProvider)
      .applyTreatment(
        aggregate,
        values[1] as Map<String, TodayTreatmentReadModel>,
      );
});

final homeTreatmentSourceProvider =
    FutureProvider<Map<String, TodayTreatmentReadModel>>((ref) async {
      final context = ref.watch(_homeRequestContextProvider);
      final service = await ref.watch(
        treatmentAdherenceQueryServiceProvider.future,
      );
      return service.days(context.date, context.end);
    });

final homeAppointmentSourceProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final context = ref.watch(_homeRequestContextProvider);
  return ref
      .watch(appointmentUseCasesProvider)
      .getByPeriod(context.date, context.end);
});

final homePrescriptionReviewCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(medicalPrescriptionUseCasesProvider).countRequiringReview();
});

final todayAgendaProvider = FutureProvider<AgendaReadModel>((ref) async {
  final context = ref.watch(_homeRequestContextProvider);
  final facade = ref.watch(homeIntelligenceQueryFacadeProvider);
  final values = await Future.wait<Object>([
    ref.watch(homeTreatmentSourceProvider.future),
    ref.watch(homeAppointmentSourceProvider.future),
  ]);
  return facade.composeAgenda(
    now: context.now,
    start: context.date,
    end: context.end,
    treatmentDays: values[0] as Map<String, TodayTreatmentReadModel>,
    appointments: values[1] as List<Appointment>,
    freshness: context.freshness,
    pendingSync: context.pendingSync,
  );
});

final treatmentSummaryProvider = FutureProvider<TreatmentSummaryReadModel>((
  ref,
) async {
  final context = ref.watch(_homeRequestContextProvider);
  final facade = ref.watch(homeIntelligenceQueryFacadeProvider);
  final days = await ref.watch(homeTreatmentSourceProvider.future);
  return facade.composeTreatmentSummary(
    days[_dateKey(context.date)],
    context.freshness,
    context.pendingSync,
  );
});

final dailyProgressProvider = FutureProvider<ProgressSummaryReadModel>((
  ref,
) async {
  final context = ref.watch(_homeRequestContextProvider);
  final facade = ref.watch(homeIntelligenceQueryFacadeProvider);
  final values = await Future.wait<Object?>([
    ref.watch(homeHealthSourceProvider.future),
    ref.watch(treatmentSummaryProvider.future),
  ]);
  final health = values[0] as HealthDashboardAggregate?;
  final profile = health?.profile;
  final latestWeight = health?.latestWeight?.weight.value;
  final proteinGoal = profile == null
      ? null
      : ProteinCalculator.goalForWeightKg(
          latestWeight ?? profile.initialWeight.value,
        );
  return facade.composeProgress(
    health: health,
    treatment: values[1] as TreatmentSummaryReadModel,
    proteinGoal: proteinGoal,
    freshness: context.freshness,
    pendingSync: context.pendingSync,
  );
});

final nextActionsProvider = FutureProvider<NextActionsReadModel>((ref) async {
  final context = ref.watch(_homeRequestContextProvider);
  final facade = ref.watch(homeIntelligenceQueryFacadeProvider);
  final values = await Future.wait<Object>([
    ref.watch(todayAgendaProvider.future),
    ref.watch(homePrescriptionReviewCountProvider.future),
  ]);
  return facade.composeNextActions(
    now: context.now,
    agenda: values[0] as AgendaReadModel,
    prescriptionsAwaitingReview: values[1] as int,
    freshness: context.freshness,
    pendingSync: context.pendingSync,
  );
});

final homeInsightsProvider = FutureProvider<InsightFeedReadModel>((ref) async {
  final context = ref.watch(_homeRequestContextProvider);
  final facade = ref.watch(homeIntelligenceQueryFacadeProvider);
  final values = await Future.wait<Object?>([
    ref.watch(homeHealthSourceProvider.future),
    ref.watch(treatmentSummaryProvider.future),
    ref.watch(todayAgendaProvider.future),
    ref.watch(homePrescriptionReviewCountProvider.future),
  ]);
  return facade.composeInsights(
    now: context.now,
    health: values[0] as HealthDashboardAggregate?,
    treatment: values[1] as TreatmentSummaryReadModel,
    agenda: values[2] as AgendaReadModel,
    prescriptionsAwaitingReview: values[3] as int,
    freshness: context.freshness,
    pendingSync: context.pendingSync,
  );
});

final quickActionsProvider = FutureProvider<QuickActionsReadModel>((ref) async {
  final context = ref.watch(_homeRequestContextProvider);
  final facade = ref.watch(homeIntelligenceQueryFacadeProvider);
  final values = await Future.wait<Object>([
    ref.watch(todayAgendaProvider.future),
    ref.watch(settingsUseCasesProvider).getSettings(),
  ]);
  return facade.composeQuickActions(
    agenda: values[0] as AgendaReadModel,
    settings: values[1] as AppSettings,
    freshness: context.freshness,
    pendingSync: context.pendingSync,
  );
});

final quickStatsProvider = FutureProvider<QuickStatsReadModel>((ref) async {
  final context = ref.watch(_homeRequestContextProvider);
  final facade = ref.watch(homeIntelligenceQueryFacadeProvider);
  final values = await Future.wait<Object?>([
    ref.watch(homeHealthSourceProvider.future),
    ref.watch(treatmentSummaryProvider.future),
  ]);
  return facade.composeQuickStats(
    values[0] as HealthDashboardAggregate?,
    values[1] as TreatmentSummaryReadModel,
    context.freshness,
    context.pendingSync,
  );
});

final todayDashboardProvider = FutureProvider<TodayDashboardReadModel>((
  ref,
) async {
  final context = ref.watch(_homeRequestContextProvider);
  final currentUserId = ref.watch(authSessionProvider)?.id;
  final timeZone = ref.watch(notificationSchedulerProvider).state.timeZone;
  final values = await Future.wait<Object?>([
    ref.watch(homeHealthSourceProvider.future),
    ref.watch(nextActionsProvider.future),
    ref.watch(todayAgendaProvider.future),
    ref.watch(treatmentSummaryProvider.future),
    ref.watch(dailyProgressProvider.future),
    ref.watch(quickStatsProvider.future),
    ref.watch(quickActionsProvider.future),
    ref.watch(homeInsightsProvider.future),
  ]);
  const HomeSessionRequestGuard().ensureCurrent(
    expectedUserId: context.userId,
    currentUserId: currentUserId,
  );
  final health = values[0] as HealthDashboardAggregate?;
  return TodayDashboardReadModel(
    userId: context.userId,
    clinicalDate: context.date,
    timeZone: timeZone ?? 'UTC',
    userName: health?.profile?.name,
    nextActions: values[1] as NextActionsReadModel,
    agenda: values[2] as AgendaReadModel,
    treatment: values[3] as TreatmentSummaryReadModel,
    progress: values[4] as ProgressSummaryReadModel,
    quickStats: values[5] as QuickStatsReadModel,
    quickActions: values[6] as QuickActionsReadModel,
    insights: values[7] as InsightFeedReadModel,
    healthScore: health?.days.firstOrNull?.healthScore,
    status: HomeSectionStatus(
      state: context.freshness.isStale
          ? HomeSectionState.stale
          : HomeSectionState.ready,
      freshness: context.freshness,
      hasPendingSync: context.pendingSync,
    ),
  );
});

final class _HomeRequestContext {
  const _HomeRequestContext({
    required this.userId,
    required this.now,
    required this.date,
    required this.end,
    required this.freshness,
    required this.pendingSync,
  });
  final String userId;
  final DateTime now;
  final DateTime date;
  final DateTime end;
  final FreshnessReadModel freshness;
  final bool pendingSync;
}

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

TodayTreatmentReadModel _emptyTreatmentDay(DateTime date) =>
    TodayTreatmentReadModel(
      date: date,
      occurrences: const [],
      adherence: const TreatmentAdherenceSummary(
        eligible: 0,
        taken: 0,
        takenOnTime: 0,
        skipped: 0,
        missed: 0,
        coverage: 0,
        coverageState: AdherenceCoverageState.unknown,
        origin: TreatmentDataOrigin.smartRoutines,
      ),
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
