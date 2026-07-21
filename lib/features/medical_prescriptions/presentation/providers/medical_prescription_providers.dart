import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_medical_prescription_local_datasource.dart';
import '../../data/repositories/drift_medical_prescription_repository.dart';
import '../../data/repositories/drift_prescription_platform_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';
import '../states/medical_prescription_state.dart';
import '../viewmodels/medical_prescription_view_model.dart';

final medicalPrescriptionRepositoryProvider =
    Provider<MedicalPrescriptionRepository>((ref) {
      final userId = ref.watch(authSessionProvider)?.id;
      if (userId == null) {
        throw StateError('Authenticated user is required for prescriptions.');
      }
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

final prescriptionPlatformRepositoryProvider =
    FutureProvider<PrescriptionPlatformRepository>((ref) async {
      final userId = ref.watch(authSessionProvider)?.id;
      if (userId == null) {
        throw StateError('Authenticated user is required for prescriptions.');
      }
      final database = await ref.read(appDatabaseProvider.future);
      final notifications = ref.read(notificationSchedulerProvider);
      final timeZone = notifications.state.timeZone ?? 'UTC';
      return DriftPrescriptionPlatformRepository(
        database: database,
        prescriptions: DriftMedicalPrescriptionLocalDatasource(
          dao: database.medicalPrescriptionDao,
          clock: ref.read(clockServiceProvider),
          userId: userId,
        ),
        clock: ref.read(clockServiceProvider),
        userId: userId,
        timeZone: timeZone,
      );
    });

final medicalPrescriptionViewModelProvider =
    NotifierProvider<MedicalPrescriptionViewModel, MedicalPrescriptionState>(
      MedicalPrescriptionViewModel.new,
    );
