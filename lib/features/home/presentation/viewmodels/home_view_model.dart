import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/usecases/use_cases.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../states/home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  late final ProfileUseCases _profileUseCases;
  late final WeightUseCases _weightUseCases;

  @override
  HomeState build() {
    _profileUseCases = ref.read(profileUseCasesProvider);
    _weightUseCases = ref.read(weightUseCasesProvider);

    return const HomeState();
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true);

    final profile = await _profileUseCases.getProfile();
    final history = await _weightUseCases.getHistory();

    state = state.copyWith(
      profile: profile,
      latestWeightRecord: history.isEmpty ? null : history.first,
      hasWeightRecords: history.isNotEmpty,
      isLoading: false,
    );
  }
}
