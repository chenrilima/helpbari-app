import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/auth/domain/entities/auth_user.dart';
import 'package:helpbari/features/onboarding/application/onboarding_completion_service.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';
import 'package:helpbari/features/onboarding/domain/repositories/repositories.dart';
import 'package:helpbari/features/onboarding/domain/usecases/use_cases.dart';
import 'package:helpbari/features/privacy/domain/entities/entities.dart';
import 'package:helpbari/features/privacy/domain/repositories/repositories.dart';
import 'package:helpbari/features/privacy/domain/usecases/use_cases.dart';
import 'package:helpbari/features/profile/domain/entities/entities.dart';
import 'package:helpbari/features/profile/domain/repositories/repositories.dart';
import 'package:helpbari/features/profile/domain/usecases/use_cases.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/use_cases.dart';
import 'package:helpbari/features/weight/domain/entities/entities.dart';
import 'package:helpbari/features/weight/domain/repositories/repositories.dart';
import 'package:helpbari/features/weight/domain/usecases/use_cases.dart';

void main() {
  late _ProfileRepository profileRepository;
  late _SettingsRepository settingsRepository;
  late _WeightRepository weightRepository;
  late _PrivacyRepository privacyRepository;
  late OnboardingCompletionService service;

  setUp(() {
    profileRepository = _ProfileRepository();
    settingsRepository = _SettingsRepository();
    weightRepository = _WeightRepository();
    privacyRepository = _PrivacyRepository();
    service = OnboardingCompletionService(
      onboarding: OnboardingUseCases(_OnboardingRepository()),
      profile: ProfileUseCases(
        getProfile: GetProfileUseCase(profileRepository),
        saveProfile: SaveProfileUseCase(profileRepository),
        updateProfile: UpdateProfileUseCase(profileRepository),
        deleteProfile: DeleteProfileUseCase(profileRepository),
      ),
      settings: SettingsUseCases(settingsRepository),
      weight: WeightUseCases(weightRepository),
      privacy: PrivacyUseCases(privacyRepository),
      now: () => DateTime.utc(2026, 7, 17, 12),
    );
  });

  test('requires Terms of Use and Privacy Policy independently', () async {
    await expectLater(
      service.complete(draft: _draft(termsAccepted: false), user: _user),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      service.complete(
        draft: _draft(privacyPolicyAccepted: false),
        user: _user,
      ),
      throwsA(isA<Exception>()),
    );

    expect(profileRepository.saveCount, 0);
    expect(privacyRepository.acceptCount, 0);
  });

  test('maps and persists Profile, Settings, Weight and consent', () async {
    final result = await service.complete(draft: _draft(), user: _user);

    expect(result.profile.name, 'Ana Lima');
    expect(result.profile.height.valueInCentimeters, 165);
    expect(result.profile.initialWeight.value, 110);
    expect(result.profile.targetWeight?.value, 72);
    expect(result.profile.surgeryType.name, 'bypass');
    expect(settingsRepository.value.dailyWaterGoalMl, 2500);
    expect(settingsRepository.value.vitaminRemindersEnabled, isFalse);
    expect(weightRepository.records.single.weight.value, 96.5);
    expect(weightRepository.records.single.id, _weightRecordId);
    expect(privacyRepository.hasConsent, isTrue);
  });

  test('does not record consent when a mandatory local save fails', () async {
    settingsRepository.failSave = true;

    await expectLater(
      service.complete(draft: _draft(), user: _user),
      throwsStateError,
    );

    expect(profileRepository.value, isNotNull);
    expect(privacyRepository.acceptCount, 0);
    expect(weightRepository.records, isEmpty);
  });

  test('retry is idempotent and does not duplicate current weight', () async {
    await service.complete(draft: _draft(), user: _user);
    await service.complete(draft: _draft(), user: _user);

    expect(weightRepository.records, hasLength(1));
    expect(privacyRepository.acceptCount, 2);
  });

  test('existing profile only requires renewed legal acceptance', () async {
    final first = await service.complete(draft: _draft(), user: _user);
    privacyRepository.hasConsent = false;
    final legalOnly = const OnboardingProfileDraft(
      termsAccepted: true,
      privacyPolicyAccepted: true,
    );

    final result = await service.complete(draft: legalOnly, user: _user);

    expect(result.profile, same(first.profile));
    expect(weightRepository.records, hasLength(1));
    expect(privacyRepository.hasConsent, isTrue);
  });
}

const _user = AuthUser(
  id: '11111111-1111-4111-8111-111111111111',
  email: 'ana@example.com',
);
const _weightRecordId = '22222222-2222-4222-8222-222222222222';

OnboardingProfileDraft _draft({
  bool termsAccepted = true,
  bool privacyPolicyAccepted = true,
}) => OnboardingProfileDraft(
  name: 'Ana Lima',
  birthDate: '10/05/1990',
  surgeryDate: '01/06/2025',
  height: '165',
  initialWeight: '110',
  currentWeight: '96,5',
  targetWeight: '72',
  surgeryType: 'bypass',
  waterGoal: '2500',
  notificationsEnabled: false,
  waterGoalConfirmed: true,
  notificationsConfirmed: true,
  termsAccepted: termsAccepted,
  privacyPolicyAccepted: privacyPolicyAccepted,
  currentWeightRecordId: _weightRecordId,
);

class _OnboardingRepository implements OnboardingRepository {
  @override
  Future<void> claimPreAuthDraft(String userId) async {}
  @override
  Future<void> clearDraft(String userId) async {}
  @override
  Future<void> completeForUser(String userId) async {}
  @override
  Future<void> completeIntroduction() async {}
  @override
  OnboardingProfileDraft getDraft(String? userId) =>
      const OnboardingProfileDraft();
  @override
  int getResumeStep(String? userId) => 0;
  @override
  bool hasCompletedForUser(String userId) => false;
  @override
  bool hasCompletedIntroduction() => false;
  @override
  bool hasConsumedDraft(String userId) => false;
  @override
  Future<void> markDraftConsumed(String userId) async {}
  @override
  Future<void> saveDraft(String? userId, OnboardingProfileDraft draft) async {}
  @override
  Future<void> saveResumeStep(String? userId, int step) async {}
}

class _ProfileRepository implements ProfileRepository {
  Profile? value;
  bool failSave = false;
  int saveCount = 0;

  @override
  Future<void> deleteProfile(Profile profile) async => value = null;
  @override
  Future<Profile?> getProfile() async => value;
  @override
  Future<void> saveProfile(Profile profile) async {
    if (failSave) throw StateError('profile failure');
    saveCount++;
    value = profile;
  }

  @override
  Future<void> updateProfile(Profile profile) => saveProfile(profile);
}

class _SettingsRepository implements SettingsRepository {
  AppSettings value = const AppSettings(
    id: '33333333-3333-4333-8333-333333333333',
  );
  bool failSave = false;

  @override
  Future<AppSettings> getSettings() async => value;
  @override
  Future<void> saveSettings(AppSettings settings) async {
    if (failSave) throw StateError('settings failure');
    value = settings;
  }
}

class _WeightRepository implements WeightRepository {
  final records = <WeightRecord>[];

  @override
  Future<void> delete(String id) async {
    records.removeWhere((record) => record.id == id);
  }

  @override
  Future<List<WeightRecord>> getHistory() async => List.of(records);
  @override
  Future<void> register(WeightRecord record) async => records.add(record);
  @override
  Future<void> update(WeightRecord record) async {
    records
      ..removeWhere((item) => item.id == record.id)
      ..add(record);
  }
}

class _PrivacyRepository implements PrivacyRepository {
  bool hasConsent = false;
  int acceptCount = 0;

  @override
  Future<PrivacyConsent> acceptCurrentDocuments() async {
    acceptCount++;
    hasConsent = true;
    return PrivacyConsent(
      id: '44444444-4444-4444-8444-444444444444',
      userId: _user.id,
      termsVersion: PrivacyDocuments.termsVersion,
      privacyVersion: PrivacyDocuments.privacyVersion,
      acceptedAt: DateTime.utc(2026, 7, 17),
      deviceId: 'device',
      timezone: 'America/Sao_Paulo',
    );
  }

  @override
  Future<void> deleteRemoteAccount({String? password}) async {}
  @override
  Future<void> deleteRemoteData({String? password}) async {}
  @override
  Future<List<PrivacyConsent>> getConsentHistory() async => const [];
  @override
  Future<bool> hasCurrentConsent() async => hasConsent;
  @override
  bool get passwordRequired => false;
  @override
  Future<void> requestDefinitiveRemoval() async {}
}
