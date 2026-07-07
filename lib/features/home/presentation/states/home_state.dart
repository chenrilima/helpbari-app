import '../../../profile/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';

class HomeState {
  const HomeState({
    this.profile,
    this.latestWeightRecord,
    this.hasWeightRecords = false,
    this.isLoading = false,
  });

  final Profile? profile;
  final WeightRecord? latestWeightRecord;
  final bool hasWeightRecords;
  final bool isLoading;

  String get userName => profile?.name ?? 'Olá';

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
    bool? hasWeightRecords,
    bool? isLoading,
  }) {
    return HomeState(
      profile: profile ?? this.profile,
      latestWeightRecord: latestWeightRecord ?? this.latestWeightRecord,
      hasWeightRecords: hasWeightRecords ?? this.hasWeightRecords,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
