import '../../../../core/services/services.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

final class LocalOnboardingRepository implements OnboardingRepository {
  const LocalOnboardingRepository(this._storage);

  static const _completedKey = 'onboarding.completed.v1';
  static const _draftKey = 'onboarding.profileDraft.v1';
  static const _introductionKey = 'onboarding.introduction.completed.v2';
  static const _userPrefix = 'onboarding.user.v2';

  final LocalStorageService _storage;

  @override
  bool hasCompletedIntroduction() =>
      _storage.getBool(_introductionKey) ??
      _storage.getBool(_completedKey) ??
      false;

  @override
  bool hasCompletedForUser(String userId) =>
      _storage.getBool('$_userPrefix.$userId.completed') ?? false;

  @override
  bool hasConsumedDraft(String userId) =>
      _storage.getBool('$_userPrefix.$userId.draftConsumed') ?? false;

  @override
  int getResumeStep(String? userId) =>
      int.tryParse(
        _storage.getString('$_userPrefix.${userId ?? 'preauth'}.step') ?? '',
      ) ??
      0;

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
  Future<void> completeIntroduction() =>
      _storage.setBool(_introductionKey, true);

  @override
  Future<void> saveResumeStep(String? userId, int step) => _storage.setString(
    '$_userPrefix.${userId ?? 'preauth'}.step',
    step.toString(),
  );

  @override
  Future<void> completeForUser(String userId) =>
      _storage.setBool('$_userPrefix.$userId.completed', true);

  @override
  Future<void> markDraftConsumed(String userId) =>
      _storage.setBool('$_userPrefix.$userId.draftConsumed', true);
}
