import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/local_weight_datasource.dart';
import '../../data/repositories/local_weight_repository.dart';
import '../../domain/repositories/repositories.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.local => LocalWeightRepository(
      LocalWeightDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Weight Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});
