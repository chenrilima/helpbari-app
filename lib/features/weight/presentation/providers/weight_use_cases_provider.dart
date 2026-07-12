import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/use_cases.dart';
import 'weight_repository_provider.dart';

final weightUseCasesProvider = Provider<WeightUseCases>((ref) {
  final repository = ref.watch(weightRepositoryProvider);

  return WeightUseCases(repository);
});
