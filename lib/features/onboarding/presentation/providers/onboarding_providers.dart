import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
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

  return OnboardingUseCases(
    getStatus: GetOnboardingStatusUseCase(repository),
    getDraft: GetOnboardingDraftUseCase(repository),
    saveDraft: SaveOnboardingDraftUseCase(repository),
    complete: CompleteOnboardingUseCase(repository),
  );
});

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
