import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/database/drift/cutover/exam_cutover_service.dart';
import '../../../../core/database/drift/migrations/exam_legacy_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/local_exam_datasource.dart';
import '../../data/datasources/drift_exam_local_datasource.dart';
import '../../data/repositories/drift_primary_exam_repository.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/usecases/exam_use_cases.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  ref.watch(repositoryBackendProvider);
  final userId = ref.watch(authSessionProvider)?.id;
  final effective = userId ?? anonymousExamUserId;
  final storage = ref.watch(localStorageServiceProvider);
  return DriftPrimaryExamRepository(
    drift: () async => DriftExamLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).examDao,
      clock: ref.read(clockServiceProvider),
      userId: effective,
    ),
    fallback: LocalExamDatasource(
      database: ref.watch(localDatabaseProvider),
      clock: ref.watch(clockServiceProvider),
    ),
    logger: ref.watch(loggerServiceProvider),
    ensureCutover: () async {
      if (userId != null) {
        await ExamCutoverService(
          database: await ref.read(appDatabaseProvider.future),
          storage: storage,
        ).attempt(userId);
      }
    },
    hasCutoverMirror: () =>
        userId != null &&
        ExamCutoverService.isCompletedMirrorFor(storage, userId),
  );
});

final examUseCasesProvider = Provider<ExamUseCases>(
  (ref) => ExamUseCases(ref.watch(examRepositoryProvider)),
);
