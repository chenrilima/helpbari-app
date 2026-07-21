import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../meals/presentation/providers/meal_use_cases_provider.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../medical_exams/presentation/providers/medical_exam_use_cases_provider.dart';
import '../../../medical_prescriptions/presentation/providers/medical_prescription_providers.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../data/repositories/pdf_medical_report_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';
import '../states/medical_report_state.dart';
import '../viewmodels/medical_report_view_model.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';

final medicalReportRepositoryProvider = Provider<MedicalReportRepository>((
  ref,
) {
  return const PdfMedicalReportRepository();
});

final medicalReportUseCasesProvider = Provider<MedicalReportUseCases>((ref) {
  final userId = ref.watch(authSessionProvider)?.id;
  if (userId == null) {
    throw StateError('Authenticated user is required for Medical Reports.');
  }
  return MedicalReportUseCases(
    repository: ref.read(medicalReportRepositoryProvider),
    profileUseCases: ref.read(profileUseCasesProvider),
    weightUseCases: ref.read(weightUseCasesProvider),
    waterUseCases: ref.read(waterUseCasesProvider),
    vitaminUseCases: ref.read(vitaminUseCasesProvider),
    medicationUseCases: ref.read(medicationUseCasesProvider),
    mealUseCases: ref.read(mealUseCasesProvider),
    appointmentUseCases: ref.read(appointmentUseCasesProvider),
    examUseCases: ref.read(medicalExamUseCasesProvider),
    settingsUseCases: ref.read(settingsUseCasesProvider),
    clock: ref.read(clockServiceProvider),
    dashboardUseCases: ref.read(healthDashboardUseCasesProvider),
    prescriptionUseCases: ref.read(medicalPrescriptionUseCasesProvider),
    treatment: () => ref.read(treatmentAdherenceQueryServiceProvider.future),
    homeIntelligence: () => ref.read(todayDashboardProvider.future),
  );
});

final medicalReportViewModelProvider =
    NotifierProvider<MedicalReportViewModel, MedicalReportState>(
      MedicalReportViewModel.new,
    );
