import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/features/onboarding/data/repositories/local_onboarding_repository.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';

void main() {
  late _Storage storage;
  late LocalOnboardingRepository repository;

  setUp(() {
    storage = _Storage();
    repository = LocalOnboardingRepository(storage);
  });

  test('first access has pending global introduction and empty draft', () {
    expect(repository.hasCompletedIntroduction(), isFalse);
    expect(repository.getDraft().name, isEmpty);
  });

  test('legacy introduction marker is read but never deleted', () {
    storage.values['onboarding.completed.v1'] = true;
    expect(repository.hasCompletedIntroduction(), isTrue);
    expect(storage.getBool('onboarding.completed.v1'), isTrue);
  });

  test('partial draft and pre-auth resume survive login', () async {
    const draft = OnboardingProfileDraft(name: 'Ana', currentWeight: '90');
    await repository.saveDraft(draft);
    await repository.saveResumeStep(null, 4);
    expect(repository.getDraft().name, 'Ana');
    expect(repository.getResumeStep(null), 4);
    expect(repository.hasCompletedForUser('user-a'), isFalse);
  });

  test(
    'skip completes only introduction and creates no user completion',
    () async {
      await repository.completeIntroduction();
      expect(repository.hasCompletedIntroduction(), isTrue);
      expect(repository.hasCompletedForUser('user-a'), isFalse);
      expect(repository.hasConsumedDraft('user-a'), isFalse);
    },
  );

  test('resume and completion are isolated for two users', () async {
    await repository.saveResumeStep('user-a', 5);
    await repository.saveResumeStep('user-b', 3);
    await repository.completeForUser('user-a');
    expect(repository.getResumeStep('user-a'), 5);
    expect(repository.getResumeStep('user-b'), 3);
    expect(repository.hasCompletedForUser('user-a'), isTrue);
    expect(repository.hasCompletedForUser('user-b'), isFalse);
  });

  test('draft consumption is idempotent and scoped once per user', () async {
    await repository.markDraftConsumed('user-a');
    await repository.markDraftConsumed('user-a');
    expect(repository.hasConsumedDraft('user-a'), isTrue);
    expect(repository.hasConsumedDraft('user-b'), isFalse);
    expect(repository.getDraft(), isNotNull);
  });

  test('new confirmation fields remain backward compatible', () {
    const legacy =
        '{"name":"Ana","waterGoal":"2500","notificationsEnabled":true}';
    final draft = OnboardingProfileDraft.decode(legacy);
    expect(draft.name, 'Ana');
    expect(draft.waterGoal, '2500');
    expect(draft.waterGoalConfirmed, isFalse);
    expect(draft.notificationsConfirmed, isFalse);
    expect(draft.currentWeightConfirmedAsInitial, isFalse);
    expect(draft.documentsAccepted, isFalse);
  });
}

class _Storage implements LocalStorageService {
  final values = <String, Object>{};
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  String? getString(String key) => values[key] as String?;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
