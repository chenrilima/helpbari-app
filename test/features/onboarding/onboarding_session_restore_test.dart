import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/bootstrap/sync_bootstrap_provider.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/features/auth/domain/entities/auth_user.dart';
import 'package:helpbari/features/auth/presentation/providers/auth_providers.dart';
import 'package:helpbari/features/onboarding/data/repositories/local_onboarding_repository.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';
import 'package:helpbari/features/onboarding/domain/repositories/repositories.dart';
import 'package:helpbari/features/onboarding/domain/usecases/use_cases.dart';
import 'package:helpbari/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:helpbari/features/onboarding/presentation/states/onboarding_state.dart';
import 'package:helpbari/features/privacy/domain/entities/entities.dart';
import 'package:helpbari/features/privacy/domain/repositories/repositories.dart';
import 'package:helpbari/features/privacy/domain/usecases/use_cases.dart';
import 'package:helpbari/features/privacy/presentation/providers/privacy_providers.dart';
import 'package:helpbari/features/profile/domain/entities/entities.dart';
import 'package:helpbari/features/profile/domain/repositories/repositories.dart';
import 'package:helpbari/features/profile/domain/usecases/use_cases.dart';
import 'package:helpbari/features/profile/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/profile/presentation/providers/profile_use_case_providers.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/use_cases.dart';
import 'package:helpbari/features/settings/presentation/providers/setting_use_cases_provider.dart';

void main() {
  const user = AuthUser(id: 'user-a', email: 'ana@example.com');

  test('existing remote-restored data marks local onboarding ready', () async {
    final fixture = _Fixture(user: user, profile: _profile(), consent: true);
    await fixture.resolve();

    expect(fixture.state.entryStatus, AppEntryStatus.authenticatedReady);
    expect(fixture.repository.hasCompletedForUser(user.id), isTrue);
    expect(fixture.repository.hasConsumedDraft(user.id), isTrue);
  });

  test(
    'new user without local or remote data remains pending safely',
    () async {
      final fixture = _Fixture(user: user, profile: null, consent: false);
      await fixture.resolve();

      expect(
        fixture.state.entryStatus,
        AppEntryStatus.authenticatedOnboardingPending,
      );
      expect(fixture.repository.hasCompletedForUser(user.id), isFalse);
    },
  );

  test('incomplete user restores available scoped draft', () async {
    final fixture = _Fixture(user: user, profile: null, consent: false);
    await fixture.repository.saveDraft(
      user.id,
      const OnboardingProfileDraft(name: 'Ana em progresso'),
    );
    await fixture.resolve();

    expect(fixture.state.draft.name, 'Ana em progresso');
    expect(fixture.state.userCompleted, isFalse);
  });

  test('stale legal documents return an existing user to acceptance', () async {
    final fixture = _Fixture(user: user, profile: _profile(), consent: false);
    await fixture.resolve();

    expect(
      fixture.state.entryStatus,
      AppEntryStatus.authenticatedLegalAcceptancePending,
    );
    expect(fixture.state.currentStep, OnboardingStep.documents);
  });

  test('legacy completion without a profile requires profile review', () async {
    final fixture = _Fixture(user: user, profile: null, consent: true);
    await fixture.repository.completeForUser(user.id);
    await fixture.resolve();

    expect(
      fixture.state.entryStatus,
      AppEntryStatus.authenticatedOnboardingPending,
    );
    expect(fixture.state.currentStep, OnboardingStep.initialData);
  });

  test(
    'legacy completion without profile does not skip required data',
    () async {
      final fixture = _Fixture(user: user, profile: null, consent: false);
      await fixture.repository.completeForUser(user.id);
      await fixture.resolve();

      expect(
        fixture.state.entryStatus,
        AppEntryStatus.authenticatedOnboardingPending,
      );
      expect(fixture.state.currentStep, OnboardingStep.initialData);
    },
  );

  test('local restoration failure never manufactures completion', () async {
    final fixture = _Fixture(
      user: user,
      profile: null,
      consent: false,
      failProfileRead: true,
    );
    await fixture.resolve();

    expect(fixture.state.entryStatus, AppEntryStatus.failure);
    expect(fixture.state.userCompleted, isFalse);
  });
}

class _Fixture {
  _Fixture({
    required this.user,
    required Profile? profile,
    required bool consent,
    bool failProfileRead = false,
  }) : _profileRepository = _ProfileRepository(
         profile,
         failRead: failProfileRead,
       ),
       _privacyRepository = _PrivacyRepository(consent),
       repository = LocalOnboardingRepository(_Storage()) {
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWithValue(user),
        syncBootstrapProvider.overrideWithValue(_SyncBootstrap()),
        onboardingUseCasesProvider.overrideWithValue(
          OnboardingUseCases(repository),
        ),
        onboardingProgressRepositoryProvider.overrideWith(
          (ref) async => _OnboardingProgressRepository(),
        ),
        profileUseCasesProvider.overrideWithValue(
          ProfileUseCases(
            getProfile: GetProfileUseCase(_profileRepository),
            saveProfile: SaveProfileUseCase(_profileRepository),
            updateProfile: UpdateProfileUseCase(_profileRepository),
            deleteProfile: DeleteProfileUseCase(_profileRepository),
          ),
        ),
        privacyUseCasesProvider.overrideWithValue(
          PrivacyUseCases(_privacyRepository),
        ),
        settingsUseCasesProvider.overrideWithValue(
          SettingsUseCases(_SettingsRepository()),
        ),
      ],
    );
  }

  final AuthUser user;
  final LocalOnboardingRepository repository;
  final _ProfileRepository _profileRepository;
  final _PrivacyRepository _privacyRepository;
  late final ProviderContainer container;

  OnboardingState get state => container.read(onboardingViewModelProvider);

  Future<void> resolve() async {
    addTearDown(container.dispose);
    container.read(onboardingViewModelProvider);
    await container
        .read(onboardingViewModelProvider.notifier)
        .refreshForSession();
  }
}

class _OnboardingProgressRepository implements OnboardingProgressRepository {
  OnboardingProgress? value;

  @override
  Future<OnboardingProgress?> getForUser() async => value;

  @override
  Future<void> save(OnboardingProgress progress) async => value = progress;
}

Profile _profile() => Profile(
  id: 'profile-a',
  name: 'Ana',
  email: 'ana@example.com',
  createdAt: AppDate(DateTime.utc(2026, 1, 1)),
  birthDate: AppDate(DateTime.utc(1990, 5, 10)),
  height: Height.create(165)!,
  initialWeight: Weight.create(110)!,
  surgeryDate: AppDate(DateTime.utc(2025, 6, 1)),
  surgeryType: SurgeryType.bypass,
);

class _SyncBootstrap implements SyncBootstrapCoordinator {
  @override
  void initialize() {}
  @override
  void onResumed() {}
  @override
  Future<void> retry() async {}
  @override
  Future<void> waitForInitialSync(
    String userId, {
    Duration timeout = const Duration(seconds: 4),
    Future<void>? cancelled,
  }) async {}
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

class _ProfileRepository implements ProfileRepository {
  _ProfileRepository(this.value, {this.failRead = false});
  Profile? value;
  final bool failRead;
  @override
  Future<void> deleteProfile(Profile profile) async => value = null;
  @override
  Future<Profile?> getProfile() async {
    if (failRead) throw StateError('database unavailable');
    return value;
  }

  @override
  Future<void> saveProfile(Profile profile) async => value = profile;
  @override
  Future<void> updateProfile(Profile profile) async => value = profile;
}

class _SettingsRepository implements SettingsRepository {
  AppSettings value = const AppSettings(id: 'settings-a');
  @override
  Future<AppSettings> getSettings() async => value;
  @override
  Future<void> saveSettings(AppSettings settings) async => value = settings;
}

class _PrivacyRepository implements PrivacyRepository {
  _PrivacyRepository(this.hasConsent);
  bool hasConsent;
  @override
  Future<PrivacyConsent> acceptCurrentDocuments() => throw UnimplementedError();
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
