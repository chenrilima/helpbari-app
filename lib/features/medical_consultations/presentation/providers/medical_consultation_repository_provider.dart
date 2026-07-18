import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_medical_consultation_local_datasource.dart';
import '../../data/repositories/drift_medical_consultation_repository.dart';
import '../../domain/repositories/medical_consultation_repository.dart';

final medicalConsultationRepositoryProvider =
    Provider<MedicalConsultationRepository>((ref) {
      final userId = ref.watch(authSessionProvider)?.id;
      final effectiveUserId = userId ?? anonymousMedicalConsultationUserId;
      return DriftMedicalConsultationRepository(
        () async => DriftMedicalConsultationLocalDatasource(
          dao: (await ref.read(
            appDatabaseProvider.future,
          )).medicalConsultationDao,
          clock: ref.read(clockServiceProvider),
          userId: effectiveUserId,
        ),
      );
    });
