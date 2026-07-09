import '../../../../core/formatters/app_weight_formatter.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../exams/domain/entities/entities.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';

class HomeState {
  const HomeState({
    this.profile,
    this.latestWeightRecord,
    this.nextAppointment,
    this.latestExam,
    this.hasWeightRecords = false,
    this.totalWaterTodayInMl = 0,
    this.pendingVitaminsCount = 0,
    this.isLoading = false,
    this.pendingMedicationsCount = 0,
    this.todayMealsCount = 0,
    this.totalProteinToday = 0,
  });

  final Profile? profile;
  final WeightRecord? latestWeightRecord;
  final Appointment? nextAppointment;
  final Exam? latestExam;
  final bool hasWeightRecords;
  final int totalWaterTodayInMl;
  final int pendingVitaminsCount;
  final bool isLoading;
  final int pendingMedicationsCount;
  final int todayMealsCount;
  final int totalProteinToday;

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

  HomeState copyWith({
    Profile? profile,
    WeightRecord? latestWeightRecord,
    Appointment? nextAppointment,
    Exam? latestExam,
    bool? hasWeightRecords,
    int? totalWaterTodayInMl,
    int? pendingVitaminsCount,
    bool? isLoading,
    int? pendingMedicationsCount,
    int? todayMealsCount,
    int? totalProteinToday,
  }) {
    return HomeState(
      profile: profile ?? this.profile,
      latestWeightRecord: latestWeightRecord ?? this.latestWeightRecord,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      latestExam: latestExam ?? this.latestExam,
      hasWeightRecords: hasWeightRecords ?? this.hasWeightRecords,
      totalWaterTodayInMl: totalWaterTodayInMl ?? this.totalWaterTodayInMl,
      pendingVitaminsCount: pendingVitaminsCount ?? this.pendingVitaminsCount,
      isLoading: isLoading ?? this.isLoading,
      pendingMedicationsCount:
          pendingMedicationsCount ?? this.pendingMedicationsCount,
      todayMealsCount: todayMealsCount ?? this.todayMealsCount,
      totalProteinToday: totalProteinToday ?? this.totalProteinToday,
    );
  }
}
