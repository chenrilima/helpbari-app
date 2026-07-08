import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_medication_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return FakeMedicationRepository();
});

final medicationUseCasesProvider = Provider<MedicationUseCases>((ref) {
  return MedicationUseCases(ref.read(medicationRepositoryProvider));
});
