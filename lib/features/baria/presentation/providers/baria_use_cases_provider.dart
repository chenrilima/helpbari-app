import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_baria_repository.dart';
import '../../domain/repositories/baria_repository.dart';
import '../../domain/usecases/baria_use_cases.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final bariaRepositoryProvider = Provider<BariaRepository>((ref) {
  ref.watch(authSessionProvider);
  final waterUseCases = ref.watch(waterUseCasesProvider);
  final settingsUseCases = ref.watch(settingsUseCasesProvider);
  final vitaminUseCases = ref.watch(vitaminUseCasesProvider);
  final medicationUseCases = ref.watch(medicationUseCasesProvider);
  final homeState = ref.watch(homeViewModelProvider);

  final healthScore = (homeState.dailySummary?.healthScore.score ?? 0.0)
      .toDouble();

  return FakeBariaRepository(
    waterUseCases: waterUseCases,
    settingsUseCases: settingsUseCases,
    vitaminUseCases: vitaminUseCases,
    medicationUseCases: medicationUseCases,
    healthScore: healthScore,
  );
});

final bariaUseCasesProvider = Provider(
  (ref) => BariaUseCases(ref.watch(bariaRepositoryProvider)),
);
