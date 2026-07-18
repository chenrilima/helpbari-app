import '../../../../core/formatters/app_water_formatter.dart';
import '../../../../core/formatters/app_weight_formatter.dart';
import '../../../../core/health/health.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../medical_consultations/domain/entities/entities.dart';
import '../../../medical_exams/domain/entities/entities.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';
import '../../domain/models/models.dart';

class HomeState {
  const HomeState({
    this.profile,
    this.latestWeightRecord,
    this.nextAppointment,
    this.latestConsultation,
    this.latestExam,
    this.hasWeightRecords = false,
    this.totalWaterTodayInMl = 0,
    this.pendingVitaminsCount = 0,
    this.isLoading = false,
    this.pendingMedicationsCount = 0,
    this.todayMealsCount = 0,
    this.totalProteinToday = 0,
    this.dailySummary,
    this.unavailableSections = const {},
    this.errorMessage,
    this.smartInsights = const [],
  });

  final Profile? profile;
  final WeightRecord? latestWeightRecord;
  final Appointment? nextAppointment;
  final MedicalConsultation? latestConsultation;
  final MedicalExam? latestExam;
  final bool hasWeightRecords;
  final int totalWaterTodayInMl;
  final int pendingVitaminsCount;
  final bool isLoading;
  final int pendingMedicationsCount;
  final int todayMealsCount;
  final int totalProteinToday;
  final DailySummary? dailySummary;
  final Set<HealthDataSection> unavailableSections;
  final String? errorMessage;
  final List<Insight> smartInsights;
  bool get hasPartialFailure => unavailableSections.isNotEmpty;

  double? get weightLost {
    final profile = this.profile;
    final latestWeightRecord = this.latestWeightRecord;

    if (profile == null || latestWeightRecord == null) {
      return null;
    }

    return profile.initialWeight.value - latestWeightRecord.weight.value;
  }

  String? get formattedWeightLost {
    final value = weightLost;

    if (value == null) return null;
    if (value == 0) return 'Peso inicial mantido';

    if (value > 0) {
      return AppWeightFormatter.lostSinceStart(value);
    }

    return AppWeightFormatter.aboveInitial(value);
  }

  String get bannerTitle {
    if (smartInsights.isNotEmpty) return smartInsights.first.title;
    final summary = dailySummary;

    if (summary == null) return 'Continue assim! 💜';

    if (summary.hydration.remainingMl > 0) {
      return 'Hidratação em progresso';
    }

    if (summary.hasPendingMedications) {
      return 'Medicamentos pendentes';
    }

    if (summary.hasRegisteredMeals) {
      return 'Rotina registrada';
    }

    if (summary.hasNextAppointment) {
      return 'Consulta agendada';
    }

    return 'Continue assim! 💜';
  }

  String get bannerMessage {
    if (smartInsights.isNotEmpty) {
      return '${smartInsights.first.message} Informação de acompanhamento, não avaliação clínica.';
    }
    final summary = dailySummary;

    if (summary == null) {
      return 'Cada registro ajuda você a acompanhar sua evolução e manter o foco.';
    }

    if (summary.hydration.remainingMl > 0) {
      final remaining = AppWaterFormatter.ml(summary.hydration.remainingMl);

      return 'Faltam $remaining para sua meta de água.';
    }

    if (summary.hasPendingMedications) {
      return summary.pendingMedications == 1
          ? 'Você tem 1 medicamento pendente.'
          : 'Você tem ${summary.pendingMedications} medicamentos pendentes.';
    }

    if (summary.hasRegisteredMeals) {
      return summary.registeredMeals == 1
          ? 'Você registrou 1 refeição hoje.'
          : 'Você registrou ${summary.registeredMeals} refeições hoje.';
    }

    if (summary.hasNextAppointment) {
      return 'Sua próxima consulta está agendada.';
    }

    return 'Cada registro ajuda você a acompanhar sua evolução e manter o foco.';
  }

  String get waterMessage {
    final summary = dailySummary;

    if (summary == null) return 'Sua hidratação de hoje.';

    if (summary.waterGoalMl <= 0) return 'Sua hidratação de hoje.';

    if (summary.hydration.remainingMl <= 0 && summary.waterGoalMl > 0) {
      return 'Meta de água atingida hoje.';
    }

    return 'Faltam ${AppWaterFormatter.ml(summary.hydration.remainingMl)} para sua meta de água.';
  }

  String get vitaminsMessage {
    final summary = dailySummary;

    if (summary == null || !summary.hasPendingVitamins) {
      return 'Nenhuma vitamina pendente hoje.';
    }

    return summary.pendingVitamins == 1
        ? 'Você tem 1 vitamina pendente.'
        : 'Você tem ${summary.pendingVitamins} vitaminas pendentes.';
  }

  String get medicationsMessage {
    final summary = dailySummary;

    if (summary == null || !summary.hasPendingMedications) {
      return 'Nenhum medicamento pendente hoje.';
    }

    return summary.pendingMedications == 1
        ? 'Você tem 1 medicamento pendente.'
        : 'Você tem ${summary.pendingMedications} medicamentos pendentes.';
  }

  String get mealsMessage {
    final summary = dailySummary;

    if (summary == null || !summary.hasRegisteredMeals) {
      return 'Nenhuma refeição registrada hoje.';
    }

    return summary.registeredMeals == 1
        ? 'Você registrou 1 refeição hoje.'
        : 'Você registrou ${summary.registeredMeals} refeições hoje.';
  }

  String get appointmentMessage {
    final summary = dailySummary;

    if (summary == null || !summary.hasNextAppointment) {
      return 'Nenhuma consulta agendada.';
    }

    return 'Sua próxima consulta está agendada.';
  }

  String get examMessage {
    final summary = dailySummary;

    if (summary == null || !summary.hasLatestExam) {
      return 'Nenhum exame cadastrado.';
    }

    return 'Seu último exame está registrado.';
  }

  String get consultationMessage {
    if (latestConsultation == null) {
      return 'Nenhuma consulta clínica registrada.';
    }

    return 'Seu último registro clínico está salvo.';
  }

  HomeState copyWith({
    Profile? profile,
    WeightRecord? latestWeightRecord,
    Appointment? nextAppointment,
    MedicalConsultation? latestConsultation,
    MedicalExam? latestExam,
    bool? hasWeightRecords,
    int? totalWaterTodayInMl,
    int? pendingVitaminsCount,
    bool? isLoading,
    int? pendingMedicationsCount,
    int? todayMealsCount,
    int? totalProteinToday,
    DailySummary? dailySummary,
    Set<HealthDataSection>? unavailableSections,
    String? errorMessage,
    bool clearError = false,
    List<Insight>? smartInsights,
  }) {
    return HomeState(
      profile: profile ?? this.profile,
      latestWeightRecord: latestWeightRecord ?? this.latestWeightRecord,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      latestConsultation: latestConsultation ?? this.latestConsultation,
      latestExam: latestExam ?? this.latestExam,
      hasWeightRecords: hasWeightRecords ?? this.hasWeightRecords,
      totalWaterTodayInMl: totalWaterTodayInMl ?? this.totalWaterTodayInMl,
      pendingVitaminsCount: pendingVitaminsCount ?? this.pendingVitaminsCount,
      isLoading: isLoading ?? this.isLoading,
      pendingMedicationsCount:
          pendingMedicationsCount ?? this.pendingMedicationsCount,
      todayMealsCount: todayMealsCount ?? this.todayMealsCount,
      totalProteinToday: totalProteinToday ?? this.totalProteinToday,
      dailySummary: dailySummary ?? this.dailySummary,
      unavailableSections: unavailableSections ?? this.unavailableSections,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      smartInsights: smartInsights ?? this.smartInsights,
    );
  }
}
