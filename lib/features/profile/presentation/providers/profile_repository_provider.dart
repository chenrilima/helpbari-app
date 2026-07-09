import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/repositories/fake_profile_repository.dart';
import '../../data/datasources/local_profile_datasource.dart';
import '../../data/repositories/local_profile_repository.dart';
import '../../domain/repositories/repositories.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.fake => FakeProfileRepository(),
    RepositoryBackend.local => LocalProfileRepository(
      LocalProfileDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Profile Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});
