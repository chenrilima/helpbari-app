import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_medical_prescription_local_datasource.dart';
import '../../data/repositories/drift_medical_prescription_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';
import '../states/medical_prescription_state.dart';
import '../viewmodels/medical_prescription_view_model.dart';

final medicalPrescriptionRepositoryProvider =
    Provider<MedicalPrescriptionRepository>((ref) {
      final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
      return DriftMedicalPrescriptionRepository(
        () async => DriftMedicalPrescriptionLocalDatasource(
          dao: (await ref.read(
            appDatabaseProvider.future,
          )).medicalPrescriptionDao,
          clock: ref.read(clockServiceProvider),
          userId: userId,
        ),
      );
    });

final medicalPrescriptionUseCasesProvider =
    Provider<MedicalPrescriptionUseCases>(
      (ref) => MedicalPrescriptionUseCases(
        ref.watch(medicalPrescriptionRepositoryProvider),
      ),
    );

final medicalPrescriptionViewModelProvider =
    NotifierProvider<MedicalPrescriptionViewModel, MedicalPrescriptionState>(
      MedicalPrescriptionViewModel.new,
    );
