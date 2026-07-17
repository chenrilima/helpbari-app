import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/bioimpedance_use_cases.dart';
import 'bioimpedance_repository_provider.dart';

final bioimpedanceUseCasesProvider = Provider<BioimpedanceUseCases>((ref) {
  return BioimpedanceUseCases(ref.watch(bioimpedanceRepositoryProvider));
});
