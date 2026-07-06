import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/use_cases.dart';
import 'weight_repository_provider.dart';

final weightUseCasesProvider = Provider<WeightUseCases>((ref) {
  final repository = ref.read(weightRepositoryProvider);

  return WeightUseCases(
    getHistory: GetWeightHistoryUseCase(repository),
    register: RegisterWeightUseCase(repository),
    update: UpdateWeightUseCase(repository),
    delete: DeleteWeightUseCase(repository),
  );
});
