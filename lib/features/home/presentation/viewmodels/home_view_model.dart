import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../appointments/domain/models/appointment_summary.dart';
import '../../../appointments/domain/usecases/use_cases.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../exams/domain/models/models.dart';
import '../../../exams/domain/usecases/use_cases.dart';
import '../../../exams/presentation/providers/exam_use_cases_provider.dart';
import '../../../medications/domain/models/models.dart';
import '../../../medications/domain/usecases/medication_use_cases.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../../water/domain/usecases/use_cases.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/domain/models/weight_summary.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../states/home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  late final ProfileUseCases _profileUseCases;
  late final WeightUseCases _weightUseCases;
  late final WaterUseCases _waterUseCases;
  late final VitaminUseCases _vitaminUseCases;
  late final AppointmentUseCases _appointmentUseCases;
  late final ExamUseCases _examUseCases;
  late final MedicationUseCases _medicationUseCases;

  @override
  HomeState build() {
    _profileUseCases = ref.read(profileUseCasesProvider);
    _weightUseCases = ref.read(weightUseCasesProvider);
    _waterUseCases = ref.read(waterUseCasesProvider);
    _vitaminUseCases = ref.read(vitaminUseCasesProvider);
    _appointmentUseCases = ref.read(appointmentUseCasesProvider);
    _examUseCases = ref.read(examUseCasesProvider);
    _medicationUseCases = ref.read(medicationUseCasesProvider);

    return const HomeState();
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true);

    final results = await Future.wait([
      _profileUseCases.getProfile(),
      _weightUseCases.getSummary(),
      _waterUseCases.getTodayTotalInMl(),
      _vitaminUseCases.getPendingCount(),
      _appointmentUseCases.getSummary(),
      _examUseCases.getSummary(),
      _medicationUseCases.getSummary(),
    ]);

    final profile = results[0] as Profile?;
    final weightSummary = results[1] as WeightSummary;
    final totalWaterToday = results[2] as int;
    final pendingVitamins = results[3] as int;
    final appointmentSummary = results[4] as AppointmentSummary;
    final examSummary = results[5] as ExamSummary;
    final medicationSummary = results[6] as MedicationSummary;

    state = state.copyWith(
      profile: profile,
      latestWeightRecord: weightSummary.latestRecord,
      hasWeightRecords: weightSummary.hasRecords,
      totalWaterTodayInMl: totalWaterToday,
      pendingVitaminsCount: pendingVitamins,
      nextAppointment: appointmentSummary.nextAppointment,
      latestExam: examSummary.latestExam,
      isLoading: false,
      pendingMedicationsCount: medicationSummary.pendingCount,
    );
  }
}
