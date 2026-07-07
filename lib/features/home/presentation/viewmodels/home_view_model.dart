import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/entities.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../../water/domain/usecases/use_cases.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/domain/models/weight_summary.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../states/home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  late final ProfileUseCases _profileUseCases;
  late final WeightUseCases _weightUseCases;
  late final WaterUseCases _waterUseCases;
  late final VitaminUseCases _vitaminUseCases;

  @override
  HomeState build() {
    _profileUseCases = ref.read(profileUseCasesProvider);
    _weightUseCases = ref.read(weightUseCasesProvider);
    _waterUseCases = ref.read(waterUseCasesProvider);
    _vitaminUseCases = ref.read(vitaminUseCasesProvider);

    return const HomeState();
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true);

    final results = await Future.wait([
      _profileUseCases.getProfile(),
      _weightUseCases.getSummary(),
      _waterUseCases.getTodayTotalInMl(),
      _vitaminUseCases.getPendingCount(),
    ]);

    final profile = results[0] as Profile?;
    final weightSummary = results[1] as WeightSummary;
    final totalWaterToday = results[2] as int;
    final pendingVitaminsCount = results[3] as int;

    state = state.copyWith(
      profile: profile,
      latestWeightRecord: weightSummary.latestRecord,
      hasWeightRecords: weightSummary.hasRecords,
      totalWaterTodayInMl: totalWaterToday,
      pendingVitaminsCount: pendingVitaminsCount,
      isLoading: false,
    );
  }
}
