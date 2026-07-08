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
      return '${value.toStringAsFixed(1)} kg perdidos desde o início';
    }

    return '${value.abs().toStringAsFixed(1)} kg acima do peso inicial';
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
    );
  }
}
