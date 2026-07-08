import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../domain/usecases/use_cases.dart';

final progressUseCasesProvider = Provider<ProgressUseCases>((ref) {
  return ProgressUseCases(
    profileUseCases: ref.read(profileUseCasesProvider),
    weightUseCases: ref.read(weightUseCasesProvider),
  );
});
