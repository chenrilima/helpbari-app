import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/local_exam_datasource.dart';
import '../../data/repositories/fake_exam_repository.dart';
import '../../data/repositories/local_exam_repository.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/usecases/exam_use_cases.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.fake => FakeExamRepository(),
    RepositoryBackend.local => LocalExamRepository(
      LocalExamDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Exam Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});

final examUseCasesProvider = Provider<ExamUseCases>(
  (ref) => ExamUseCases(ref.read(examRepositoryProvider)),
);
