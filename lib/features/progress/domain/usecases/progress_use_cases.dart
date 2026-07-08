import '../../../profile/domain/usecases/use_cases.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../models/models.dart';

class ProgressUseCases {
  const ProgressUseCases({
    required ProfileUseCases profileUseCases,
    required WeightUseCases weightUseCases,
  }) : _profileUseCases = profileUseCases,
       _weightUseCases = weightUseCases;

  final ProfileUseCases _profileUseCases;
  final WeightUseCases _weightUseCases;

  Future<ProgressSummary?> getSummary() async {
    final profile = await _profileUseCases.getProfile();

    if (profile == null) return null;

    final weightSummary = await _weightUseCases.getSummary();

    return ProgressSummary(
      profile: profile,
      latestWeightRecord: weightSummary.latestRecord,
    );
  }
}
