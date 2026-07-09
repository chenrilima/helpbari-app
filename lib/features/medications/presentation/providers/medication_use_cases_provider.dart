import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/local_medication_datasource.dart';
import '../../data/repositories/fake_medication_repository.dart';
import '../../data/repositories/local_medication_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.fake => FakeMedicationRepository(),
    RepositoryBackend.local => LocalMedicationRepository(
      LocalMedicationDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Medication Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});

final medicationUseCasesProvider = Provider<MedicationUseCases>((ref) {
  return MedicationUseCases(ref.read(medicationRepositoryProvider));
});
