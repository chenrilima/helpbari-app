import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/local_water_datasource.dart';
import '../../data/repositories/fake_water_repository.dart';
import '../../data/repositories/local_water_repository.dart';
import '../../domain/repositories/water_repository.dart';
import '../../domain/usecases/use_cases.dart';

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.fake => FakeWaterRepository(),
    RepositoryBackend.local => LocalWaterRepository(
      LocalWaterDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Water Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});

final waterUseCasesProvider = Provider(
  (ref) => WaterUseCases(
    ref.read(waterRepositoryProvider),
    ref.read(clockServiceProvider),
  ),
);
