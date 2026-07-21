import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/service_providers.dart';
import '../database/drift/drift_database_providers.dart';
import '../supabase/database/supabase_database_provider.dart';
import '../supabase/supabase_client_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/charts/presentation/providers/chart_series_providers.dart';
import '../../features/home/presentation/providers/home_view_model_provider.dart';
import '../../features/home/application/home_sync_invalidation_policy.dart';
import '../../features/settings/data/datasources/drift_settings_local_datasource.dart';
import '../../features/settings/data/datasources/settings_supabase_datasource.dart';
import '../../features/settings/data/repositories/settings_sync_repository.dart';
import '../../features/settings/presentation/providers/setting_use_cases_provider.dart';
import '../../features/settings/presentation/providers/setting_view_model_provider.dart';
import '../../features/settings/presentation/providers/settings_reminder_sync_provider.dart';
import '../../features/profile/data/datasources/drift_profile_local_datasource.dart';
import '../../features/profile/data/datasources/profile_supabase_datasource.dart';
import '../../features/profile/data/repositories/profile_sync_repository.dart';
import '../../features/profile/presentation/providers/profile_view_model_provider.dart';
import '../../features/privacy/data/datasources/drift_privacy_consent_datasource.dart';
import '../../features/privacy/data/repositories/privacy_consent_sync_repository.dart';
import '../../features/privacy/presentation/providers/privacy_providers.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/onboarding/data/datasources/drift_onboarding_progress_datasource.dart';
import '../../features/onboarding/data/datasources/onboarding_progress_supabase_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_progress_sync_repository.dart';
import '../../features/medical_reports/presentation/providers/medical_report_providers.dart';
import '../../features/water/data/datasources/drift_water_local_datasource.dart';
import '../../features/water/data/datasources/water_supabase_datasource.dart';
import '../../features/water/data/repositories/water_sync_repository.dart';
import '../../features/water/presentation/providers/water_view_model_provider.dart';
import '../../features/weight/data/datasources/drift_weight_local_datasource.dart';
import '../../features/weight/data/datasources/weight_supabase_datasource.dart';
import '../../features/weight/data/repositories/weight_sync_repository.dart';
import '../../features/weight/presentation/providers/weight_view_model_provider.dart';
import '../../features/meals/data/datasources/drift_meal_local_datasource.dart';
import '../../features/meals/data/datasources/meal_supabase_datasource.dart';
import '../../features/meals/data/repositories/meal_sync_repository.dart';
import '../../features/meals/presentation/providers/meal_view_model_provider.dart';
import '../../features/meals/presentation/providers/meal_use_cases_provider.dart';
import '../../features/appointments/data/datasources/drift_appointment_local_datasource.dart';
import '../../features/appointments/data/datasources/appointment_supabase_datasource.dart';
import '../../features/appointments/data/repositories/appointment_sync_repository.dart';
import '../../features/appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../features/appointments/presentation/providers/appointment_view_model_provider.dart';
import '../../features/exams/data/datasources/drift_exam_local_datasource.dart';
import '../../features/exams/data/datasources/exam_supabase_datasource.dart';
import '../../features/exams/data/repositories/exam_sync_repository.dart';
import '../../features/exams/presentation/providers/exam_use_cases_provider.dart';
import '../../features/exams/presentation/providers/exam_view_model_provider.dart';
import '../../features/vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../features/vitamins/presentation/providers/vitamin_view_model_provider.dart';
import '../../features/medications/presentation/providers/medication_use_cases_provider.dart';
import '../../features/medications/presentation/providers/medication_view_model_provider.dart';
import '../../features/bioimpedance/data/datasources/bioimpedance_supabase_datasource.dart';
import '../../features/bioimpedance/data/datasources/drift_bioimpedance_local_datasource.dart';
import '../../features/bioimpedance/data/repositories/bioimpedance_sync_repository.dart';
import '../../features/bioimpedance/presentation/providers/bioimpedance_use_cases_provider.dart';
import '../../features/bioimpedance/presentation/providers/bioimpedance_view_model_provider.dart';
import '../../features/document_intelligence/data/datasources/document_processing_supabase_datasource.dart';
import '../../features/document_intelligence/data/repositories/document_processing_sync_repository.dart';
import '../../features/medical_exams/data/datasources/drift_medical_exam_local_datasource.dart';
import '../../features/medical_exams/data/datasources/medical_exam_supabase_datasource.dart';
import '../../features/medical_exams/data/repositories/medical_exam_sync_repository.dart';
import '../../features/medical_prescriptions/data/datasources/drift_medical_prescription_local_datasource.dart';
import '../../features/medical_prescriptions/data/datasources/medical_prescription_supabase_datasource.dart';
import '../../features/medical_prescriptions/data/repositories/medical_prescription_sync_repository.dart';
import '../../features/medical_prescriptions/data/repositories/prescription_platform_sync_repository.dart';
import '../../features/smart_routines/data/datasources/drift_smart_routine_datasource.dart';
import '../../features/smart_routines/data/datasources/smart_routine_supabase_datasource.dart';
import '../../features/smart_routines/data/repositories/smart_routines_sync_repository.dart';
import '../../features/progress/presentation/providers/progress_view_model_provider.dart';
import '../../features/baria/presentation/providers/baria_view_model_provider.dart';
import 'sync_engine.dart';
import 'sync_result.dart';
import 'sync_session.dart';
import 'sync_manager.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';
import 'syncable_repository.dart';

final syncConnectivityChangesProvider = Provider<Stream<bool>>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((result) => result != ConnectivityResult.none),
  );
});

final syncableRepositoriesProvider = Provider<List<SyncableRepository>>((ref) {
  final user = ref.watch(authSessionProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final database = ref.watch(appDatabaseProvider).value;

  if (user == null || supabaseClient == null) {
    return const [];
  }
  if (database == null) {
    return const [];
  }

  return [
    OnboardingProgressSyncRepository(
      local: () async => DriftOnboardingProgressDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).onboardingStateDao,
        userId: user.id,
      ),
      remote: OnboardingProgressSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    PrivacyConsentSyncRepository(
      local: () async => DriftPrivacyConsentDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).privacyConsentDao,
        userId: user.id,
      ),
      remote: ref.watch(privacyRemoteDatasourceProvider)!,
      userId: user.id,
    ),
    ProfileSyncRepository(
      local: () async {
        if (!ref.read(driftAvailableProvider)) {
          throw StateError('Drift unavailable');
        }
        final database = await ref.read(appDatabaseProvider.future);
        return DriftProfileLocalDatasource(
          dao: database.profileDao,
          clock: ref.read(clockServiceProvider),
          userId: user.id,
        );
      },
      remote: ProfileSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
    ),
    WaterSyncRepository(
      localDatasource: () async {
        if (!ref.read(driftAvailableProvider)) {
          throw StateError('Drift unavailable');
        }
        final database = await ref.read(appDatabaseProvider.future);
        return DriftWaterLocalDatasource(
          dao: database.waterDao,
          clock: ref.read(clockServiceProvider),
          userId: user.id,
        );
      },
      supabaseDatasource: WaterSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    WeightSyncRepository(
      local: () async => DriftWeightLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).weightDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: WeightSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
    ),
    MealSyncRepository(
      local: () async => DriftMealLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).mealDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: MealSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
    ),
    AppointmentSyncRepository(
      local: () async => DriftAppointmentLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).appointmentDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: AppointmentSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
      afterRemoteCommit: (dto) async {
        try {
          await ref
              .read(appointmentReminderServiceProvider)
              .applyAfterCommit(dto.toEntity());
        } catch (error) {
          ref
              .read(loggerServiceProvider)
              .warning(
                'Appointment notification reconciliation failed (${error.runtimeType}).',
              );
        }
      },
    ),
    // Compatibilidade transitória:
    // mantém o sync legado apenas para concluir pendências/tombstones já
    // existentes em exam_records. A fonte funcional do app já é medical_exams.
    ExamSyncRepository(
      local: () async => DriftExamLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).examDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: ExamSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
    ),
    MedicalExamSyncRepository(
      local: () async => DriftMedicalExamLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).medicalExamDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: MedicalExamSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    MedicalPrescriptionSyncRepository(
      local: () async => DriftMedicalPrescriptionLocalDatasource(
        dao: (await ref.read(
          appDatabaseProvider.future,
        )).medicalPrescriptionDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: MedicalPrescriptionSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    BioimpedanceSyncRepository(
      local: () async => DriftBioimpedanceLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).bioimpedanceDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: BioimpedanceSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    DocumentProcessingSyncRepository(
      local: () async =>
          (await ref.read(appDatabaseProvider.future)).documentIntelligenceDao,
      remote: DocumentProcessingSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    SmartRoutinesSyncRepository(
      local: () async => DriftSmartRoutineDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).smartRoutineDao,
        userId: user.id,
      ),
      remote: SmartRoutineSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    PrescriptionPlatformSyncRepository(
      database: database,
      remote: ref.watch(supabaseDatabaseProvider),
      userId: user.id,
    ),
    SettingsSyncRepository(
      local: () async {
        if (!ref.read(driftAvailableProvider)) {
          throw StateError('Drift unavailable');
        }
        final database = await ref.read(appDatabaseProvider.future);
        return DriftSettingsLocalDatasource(
          dao: database.settingsDao,
          clock: ref.read(clockServiceProvider),
          userId: user.id,
        );
      },
      remote: SettingsSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
      afterCommit: (dto) async {
        await ref
            .read(settingsReminderSyncServiceProvider)
            .applyAfterCommit(dto.toEntity());
      },
    ),
  ];
});

final syncAppVersionProvider = Provider<String>((ref) {
  return 'unknown';
});

final syncUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authSessionProvider)?.id;
});

final syncSessionRegistryProvider = Provider<SyncSessionRegistry>((ref) {
  final registry = SyncSessionRegistry();
  ref.listen(
    authSessionProvider,
    (previous, next) => registry.activate(next?.id),
    fireImmediately: true,
  );
  return registry;
});

final syncStateRepositoryProvider = Provider<SyncStateRepository>((ref) {
  return LocalSyncStateRepository(
    storage: ref.watch(localStorageServiceProvider),
    uuidService: ref.watch(uuidServiceProvider),
  );
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    stateRepository: ref.watch(syncStateRepositoryProvider),
    clock: ref.watch(clockServiceProvider),
  );
});

final syncDataRefreshProvider = Provider<Future<void> Function(SyncResult)>((
  ref,
) {
  return (result) async {
    final currentUserId = ref.read(authSessionProvider)?.id;
    if (!result.belongsTo(currentUserId)) return;
    final domains = result.domainsChanged;
    final homeAreas = const HomeSyncInvalidationPolicy().areasFor(domains);
    if (domains.isEmpty && !result.fullRefreshRequired) return;
    if (!result.fullRefreshRequired) {
      if (domains.contains(SyncDomain.water)) {
        if (homeAreas.contains(HomeRefreshArea.healthSource)) {
          ref.invalidate(homeHealthBaseSourceProvider);
        }
        ref.invalidate(waterViewModelProvider);
        ref.invalidate(waterChartSeriesProvider);
        ref.invalidate(dailyProgressProvider);
        ref.invalidate(homeInsightsProvider);
      }
      if (domains.contains(SyncDomain.weight)) {
        if (homeAreas.contains(HomeRefreshArea.healthSource)) {
          ref.invalidate(homeHealthBaseSourceProvider);
        }
        ref.invalidate(weightViewModelProvider);
        ref.invalidate(weightChartSeriesProvider);
        ref.invalidate(progressTrendProvider);
        ref.invalidate(dailyProgressProvider);
        ref.invalidate(homeInsightsProvider);
      }
      if (domains.contains(SyncDomain.meals)) {
        if (homeAreas.contains(HomeRefreshArea.healthSource)) {
          ref.invalidate(homeHealthBaseSourceProvider);
        }
        ref.invalidate(mealViewModelProvider);
        ref.invalidate(dailyProgressProvider);
        ref.invalidate(homeInsightsProvider);
      }
      if (domains.contains(SyncDomain.appointments)) {
        if (homeAreas.contains(HomeRefreshArea.appointmentSource)) {
          ref.invalidate(homeAppointmentSourceProvider);
        }
        ref.invalidate(appointmentViewModelProvider);
        ref.invalidate(todayAgendaProvider);
        ref.invalidate(nextActionsProvider);
      }
      if (domains.contains(SyncDomain.exams)) {
        ref.invalidate(examViewModelProvider);
      }
      if (domains.contains(SyncDomain.treatment)) {
        if (homeAreas.contains(HomeRefreshArea.treatmentSource)) {
          ref.invalidate(homeTreatmentSourceProvider);
        }
        ref.invalidate(treatmentSummaryProvider);
        ref.invalidate(todayAgendaProvider);
        ref.invalidate(nextActionsProvider);
        ref.invalidate(dailyProgressProvider);
        ref.invalidate(homeInsightsProvider);
      }
      if (domains.contains(SyncDomain.prescriptions)) {
        if (homeAreas.contains(HomeRefreshArea.prescriptionSource)) {
          ref.invalidate(homePrescriptionReviewCountProvider);
        }
        ref.invalidate(nextActionsProvider);
        ref.invalidate(homeInsightsProvider);
      }
      if (domains.contains(SyncDomain.settings)) {
        if (homeAreas.contains(HomeRefreshArea.healthSource)) {
          ref.invalidate(homeHealthBaseSourceProvider);
        }
        ref.invalidate(settingsUseCasesProvider);
        ref.invalidate(settingsViewModelProvider);
        ref.invalidate(dailyWaterGoalProvider);
      }
      if (domains.contains(SyncDomain.profile)) {
        if (homeAreas.contains(HomeRefreshArea.healthSource)) {
          ref.invalidate(homeHealthBaseSourceProvider);
        }
        ref.invalidate(profileViewModelProvider);
      }
      if (domains.contains(SyncDomain.vitamins)) {
        ref.invalidate(vitaminViewModelProvider);
      }
      if (domains.contains(SyncDomain.medications)) {
        ref.invalidate(medicationViewModelProvider);
      }
      if (domains.contains(SyncDomain.bioimpedance)) {
        ref.invalidate(bioimpedanceViewModelProvider);
      }
      if (domains.contains(SyncDomain.documents)) {
        ref.invalidate(medicalReportViewModelProvider);
      }
      if (domains.contains(SyncDomain.privacy)) {
        ref.invalidate(privacyViewModelProvider);
      }
      if (domains.contains(SyncDomain.onboarding)) {
        ref.invalidate(onboardingProgressRepositoryProvider);
        ref.invalidate(onboardingProgressServiceProvider);
        await ref
            .read(onboardingViewModelProvider.notifier)
            .refreshForSession(waitForRemote: false);
      }
      if (homeAreas.contains(HomeRefreshArea.dashboard)) {
        ref.invalidate(todayDashboardProvider);
      }
      return;
    }
    ref.invalidate(settingsUseCasesProvider);
    ref.invalidate(onboardingProgressRepositoryProvider);
    ref.invalidate(onboardingProgressServiceProvider);
    ref.invalidate(dailyWaterGoalProvider);
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(healthDashboardUseCasesProvider);
    ref.invalidate(healthPeriodAggregateProvider);
    ref.invalidate(waterViewModelProvider);
    ref.invalidate(weightViewModelProvider);
    ref.invalidate(mealUseCasesProvider);
    ref.invalidate(mealViewModelProvider);
    ref.invalidate(appointmentUseCasesProvider);
    ref.invalidate(appointmentViewModelProvider);
    ref.invalidate(examUseCasesProvider);
    ref.invalidate(examViewModelProvider);
    ref.invalidate(vitaminUseCasesProvider);
    ref.invalidate(vitaminViewModelProvider);
    ref.invalidate(vitaminAdherenceChartSeriesProvider);
    ref.invalidate(medicationUseCasesProvider);
    ref.invalidate(medicationViewModelProvider);
    ref.invalidate(bioimpedanceUseCasesProvider);
    ref.invalidate(bioimpedanceViewModelProvider);
    ref.invalidate(medicationAdherenceChartSeriesProvider);
    ref.invalidate(weightChartSeriesProvider);
    ref.invalidate(progressViewModelProvider);
    ref.invalidate(waterChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
    ref.invalidate(profileViewModelProvider);
    ref.invalidate(privacyRepositoryProvider);
    ref.invalidate(privacyViewModelProvider);
    await ref
        .read(onboardingViewModelProvider.notifier)
        .refreshForSession(waitForRemote: false);
    await ref.read(settingsViewModelProvider.notifier).loadSettings();
    await Future.wait([
      ref.read(waterViewModelProvider.notifier).loadHistory(),
      ref.read(weightViewModelProvider.notifier).loadHistory(),
      ref.read(mealViewModelProvider.notifier).loadMeals(),
      ref.read(appointmentViewModelProvider.notifier).loadAppointments(),
      ref.read(examViewModelProvider.notifier).loadItems(),
      ref.read(vitaminViewModelProvider.notifier).loadVitamins(),
      ref.read(medicationViewModelProvider.notifier).loadMedications(),
      ref.read(bioimpedanceViewModelProvider.notifier).loadHistory(),
      ref.read(bariaViewModelProvider.notifier).loadDailyInsight(),
      ref.read(profileViewModelProvider.notifier).loadProfile(),
    ]);
    try {
      final settings = await ref.read(settingsUseCasesProvider).getSettings();
      await ref.read(settingsReminderSyncServiceProvider).restore(settings);
    } catch (error) {
      ref
          .read(loggerServiceProvider)
          .warning(
            'Notification restore after sync failed (${error.runtimeType}).',
          );
    }
  };
});

final syncManagerProvider = NotifierProvider<SyncManager, SyncState>(
  SyncManager.new,
);
