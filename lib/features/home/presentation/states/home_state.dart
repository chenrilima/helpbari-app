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
