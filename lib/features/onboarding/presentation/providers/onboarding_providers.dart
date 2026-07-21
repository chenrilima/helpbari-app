import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../application/onboarding_progress_service.dart';
import '../../data/datasources/drift_onboarding_progress_datasource.dart';
import '../../data/repositories/drift_onboarding_progress_repository.dart';
import '../../../privacy/presentation/providers/privacy_providers.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../application/onboarding_completion_service.dart';
import '../../data/repositories/local_onboarding_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';
import '../states/onboarding_state.dart';
import '../viewmodels/onboarding_view_model.dart';

final onboardingSessionReadTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 8),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return LocalOnboardingRepository(ref.watch(localStorageServiceProvider));
});

final onboardingUseCasesProvider = Provider<OnboardingUseCases>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);

  return OnboardingUseCases(repository);
});

final onboardingProgressRepositoryProvider =
    FutureProvider<OnboardingProgressRepository>((ref) async {
      final database = await ref.watch(appDatabaseProvider.future);
      final user = ref.watch(authSessionProvider);
      if (user == null) {
        throw StateError('Authenticated user required for onboarding state.');
      }
      return DriftOnboardingProgressRepository(
        datasource: DriftOnboardingProgressDatasource(
          dao: database.onboardingStateDao,
          userId: user.id,
        ),
        now: ref.watch(clockServiceProvider).now,
      );
    });

final onboardingProgressServiceProvider =
    FutureProvider<OnboardingProgressService>((ref) async {
      return OnboardingProgressService(
        repository: await ref.watch(
          onboardingProgressRepositoryProvider.future,
        ),
        legacy: ref.watch(onboardingUseCasesProvider),
        profile: ref.watch(profileUseCasesProvider),
        privacy: ref.watch(privacyUseCasesProvider),
        newId: ref.watch(uuidServiceProvider).generate,
        now: ref.watch(clockServiceProvider).now,
      );
    });

final onboardingCompletionServiceProvider =
    Provider<OnboardingCompletionService>((ref) {
      return OnboardingCompletionService(
        onboarding: ref.watch(onboardingUseCasesProvider),
        profile: ref.watch(profileUseCasesProvider),
        settings: ref.watch(settingsUseCasesProvider),
        weight: ref.watch(weightUseCasesProvider),
        privacy: ref.watch(privacyUseCasesProvider),
        now: ref.watch(clockServiceProvider).now,
      );
    });

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
