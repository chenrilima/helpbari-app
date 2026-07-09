import '../../../../core/services/services.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

final class LocalOnboardingRepository implements OnboardingRepository {
  const LocalOnboardingRepository(this._storage);

  static const _completedKey = 'onboarding.completed.v1';
  static const _draftKey = 'onboarding.profileDraft.v1';

  final LocalStorageService _storage;

  @override
  bool hasCompletedOnboarding() {
    return _storage.getBool(_completedKey) ?? false;
  }

  @override
  OnboardingProfileDraft getDraft() {
    final encoded = _storage.getString(_draftKey);

    if (encoded == null) {
      return const OnboardingProfileDraft();
    }

    return OnboardingProfileDraft.decode(encoded);
  }

  @override
  Future<void> saveDraft(OnboardingProfileDraft draft) async {
    await _storage.setString(_draftKey, draft.encode());
  }

  @override
  Future<void> complete(OnboardingProfileDraft draft) async {
    await saveDraft(draft);
    await _storage.setBool(_completedKey, true);
  }
}
