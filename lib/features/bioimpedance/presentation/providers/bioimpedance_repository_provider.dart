import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_bioimpedance_local_datasource.dart';
import '../../data/repositories/drift_bioimpedance_repository.dart';
import '../../domain/repositories/bioimpedance_repository.dart';

final bioimpedanceRepositoryProvider = Provider<BioimpedanceRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id;
  final effectiveUserId = userId ?? anonymousBioimpedanceUserId;
  return DriftBioimpedanceRepository(
    () async => DriftBioimpedanceLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).bioimpedanceDao,
      clock: ref.read(clockServiceProvider),
      userId: effectiveUserId,
    ),
  );
});
