import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/medical_consultation_use_cases.dart';
import 'medical_consultation_repository_provider.dart';

final medicalConsultationUseCasesProvider =
    Provider<MedicalConsultationUseCases>(
      (ref) => MedicalConsultationUseCases(
        ref.watch(medicalConsultationRepositoryProvider),
      ),
    );
