import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_vitamin_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/vitamin_use_cases.dart';

final vitaminRepositoryProvider = Provider<VitaminRepository>((ref) {
  return FakeVitaminRepository();
});

final vitaminUseCasesProvider = Provider<VitaminUseCases>((ref) {
  return VitaminUseCases(ref.read(vitaminRepositoryProvider));
});
