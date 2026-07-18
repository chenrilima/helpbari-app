import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_medical_exam_local_datasource.dart';
import '../../data/repositories/drift_medical_exam_repository.dart';
import '../../domain/repositories/medical_exam_repository.dart';

final medicalExamRepositoryProvider = Provider<MedicalExamRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id;
  final effectiveUserId = userId ?? anonymousMedicalExamUserId;
  return DriftMedicalExamRepository(
    () async => DriftMedicalExamLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).medicalExamDao,
      clock: ref.read(clockServiceProvider),
      userId: effectiveUserId,
    ),
  );
});
