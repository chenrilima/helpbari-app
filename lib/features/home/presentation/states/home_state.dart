import '../../../appointments/domain/entities/entities.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';

class HomeState {
  const HomeState({
    this.profile,
    this.latestWeightRecord,
    this.nextAppointment,
    this.hasWeightRecords = false,
    this.totalWaterTodayInMl = 0,
    this.pendingVitaminsCount = 0,
    this.isLoading = false,
  });

  final Profile? profile;

  final WeightRecord? latestWeightRecord;

  final Appointment? nextAppointment;

  final bool hasWeightRecords;

  final int totalWaterTodayInMl;

  final int pendingVitaminsCount;

  final bool isLoading;

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

    if (value == null) {
      return null;
    }

    if (value == 0) {
      return 'Peso inicial mantido';
    }

    if (value > 0) {
      return '${value.toStringAsFixed(1)} kg perdidos desde o início';
    }

    return '${value.abs().toStringAsFixed(1)} kg acima do peso inicial';
  }

  HomeState copyWith({
    Profile? profile,
    WeightRecord? latestWeightRecord,
    Appointment? nextAppointment,
    bool? hasWeightRecords,
    int? totalWaterTodayInMl,
    int? pendingVitaminsCount,
    bool? isLoading,
  }) {
    return HomeState(
      profile: profile ?? this.profile,
      latestWeightRecord: latestWeightRecord ?? this.latestWeightRecord,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      hasWeightRecords: hasWeightRecords ?? this.hasWeightRecords,
      totalWaterTodayInMl: totalWaterTodayInMl ?? this.totalWaterTodayInMl,
      pendingVitaminsCount: pendingVitaminsCount ?? this.pendingVitaminsCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
