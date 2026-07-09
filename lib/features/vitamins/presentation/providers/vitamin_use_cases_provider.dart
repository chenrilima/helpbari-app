import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/local_vitamin_datasource.dart';
import '../../data/repositories/fake_vitamin_repository.dart';
import '../../data/repositories/local_vitamin_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/vitamin_use_cases.dart';

final vitaminRepositoryProvider = Provider<VitaminRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.fake => FakeVitaminRepository(),
    RepositoryBackend.local => LocalVitaminRepository(
      LocalVitaminDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Vitamin Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});

final vitaminUseCasesProvider = Provider<VitaminUseCases>((ref) {
  return VitaminUseCases(ref.read(vitaminRepositoryProvider));
});
