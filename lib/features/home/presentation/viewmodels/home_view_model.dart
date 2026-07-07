import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../water/domain/usecases/water_use_cases.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/domain/models/weight_summary.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../states/home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  late final ProfileUseCases _profileUseCases;
  late final WeightUseCases _weightUseCases;
  late final WaterUseCases _waterUseCases;

  @override
  HomeState build() {
    _profileUseCases = ref.read(profileUseCasesProvider);
    _weightUseCases = ref.read(weightUseCasesProvider);
    _waterUseCases = ref.read(waterUseCasesProvider);

    return const HomeState();
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true);

    final results = await Future.wait([
      _profileUseCases.getProfile(),
      _weightUseCases.getSummary(),
      _waterUseCases.getTodayTotalInMl(),
    ]);

    final summary = results[1] as WeightSummary;

    state = state.copyWith(
      profile: results[0] as Profile?,
      latestWeightRecord: summary.latestRecord,
      hasWeightRecords: summary.hasRecords,
      totalWaterTodayInMl: results[2] as int,
      isLoading: false,
    );
  }
}
