import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
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

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return LocalOnboardingRepository(ref.watch(localStorageServiceProvider));
});

final onboardingUseCasesProvider = Provider<OnboardingUseCases>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);

  return OnboardingUseCases(repository);
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
