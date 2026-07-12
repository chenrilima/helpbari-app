import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/supabase/database/supabase_database_provider.dart';
import '../../../../core/supabase/interceptors/supabase_interceptors_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../../medical_reports/domain/entities/report_template.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../application/privacy_deletion_service.dart';
import '../../application/privacy_export_service.dart';
import '../../data/datasources/drift_privacy_consent_datasource.dart';
import '../../data/datasources/privacy_supabase_datasource.dart';
import '../../data/repositories/drift_privacy_repository.dart';
import '../../data/services/privacy_local_cleanup_service.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';
import '../states/privacy_state.dart';
import '../viewmodels/privacy_view_model.dart';

final privacyRemoteDatasourceProvider = Provider<PrivacyRemoteDatasource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PrivacySupabaseDatasource(
    database: ref.watch(supabaseDatabaseProvider),
    client: client,
    interceptor: ref.watch(supabaseInterceptorRunnerProvider),
  );
});

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return DriftPrivacyRepository(
    local: () async => DriftPrivacyConsentDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).privacyConsentDao,
      userId: userId,
    ),
    remote: ref.watch(privacyRemoteDatasourceProvider),
    clock: ref.watch(clockServiceProvider),
    uuid: ref.watch(uuidServiceProvider),
    userId: userId,
    deviceId: () async {
      final state = await ref.read(syncStateRepositoryProvider).getState();
      return state.deviceId ?? ref.read(uuidServiceProvider).generate();
    },
    timezone: () async {
      try {
        return (await FlutterTimezone.getLocalTimezone()).identifier;
      } catch (_) {
        return 'UTC';
      }
    },
  );
});

final privacyUseCasesProvider = Provider<PrivacyUseCases>(
  (ref) => PrivacyUseCases(ref.watch(privacyRepositoryProvider)),
);

final privacyExportServiceProvider = Provider<PrivacyExportService>((ref) {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  return PrivacyExportService(
    loadReport: () => ref
        .read(medicalReportUseCasesProvider)
        .buildSnapshot(template: ReportTemplate.complete()),
    loadSettings: () => ref.read(settingsUseCasesProvider).getSettings(),
    loadVitaminLogs: ref.read(vitaminUseCasesProvider).getLogs,
    loadMedicationLogs: ref.read(medicationUseCasesProvider).getLogs,
    clock: ref.read(clockServiceProvider),
    userId: userId,
  );
});

final privacyDeletionServiceProvider = FutureProvider<PrivacyDeletionService>((
  ref,
) async {
  final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
  final auth = ref.read(authUseCasesProvider);
  return PrivacyDeletionService(
    privacy: ref.read(privacyUseCasesProvider),
    localCleanup: PrivacyLocalCleanupService(
      database: await ref.read(appDatabaseProvider.future),
      preferences: ref.read(sharedPreferencesProvider),
    ),
    logout: () async {
      if (auth.getCurrentUser() == null) return;
      final result = await auth.signOut();
      if (result case Failure(:final exception)) throw exception;
    },
    userId: userId,
  );
});

final privacyViewModelProvider =
    NotifierProvider<PrivacyViewModel, PrivacyState>(PrivacyViewModel.new);
