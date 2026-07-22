import 'dart:async';

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

  test(
    'pending local restoration leaves splash with recoverable failure',
    () async {
      final fixture = _Fixture(
        user: user,
        profile: null,
        consent: false,
        hangProfileRead: true,
        sessionReadTimeout: const Duration(milliseconds: 10),
      );
      await fixture.resolve();

      expect(fixture.state.entryStatus, AppEntryStatus.failure);
      expect(fixture.state.isResolvingSession, isFalse);
      expect(fixture.state.userCompleted, isFalse);
    },
  );

  test('three simultaneous refreshes share one active resolution', () async {
    final fixture = _Fixture(
      user: user,
      profile: null,
      consent: false,
      blockProgressRead: true,
    );
    addTearDown(fixture.container.dispose);
    fixture.container.read(onboardingViewModelProvider);
    final notifier = fixture.container.read(
      onboardingViewModelProvider.notifier,
    );

    final refreshes = <Future<void>>[
      notifier.refreshForSession(),
      notifier.refreshForSession(),
      notifier.refreshForSession(),
    ];
    await Future<void>.delayed(Duration.zero);
    expect(fixture.progressRepository.activeReads, 1);
    expect(fixture.progressRepository.maxConcurrentReads, 1);

    fixture.progressRepository.release();
    await Future.wait(refreshes);
    expect(fixture.progressRepository.maxConcurrentReads, 1);
  });

  test('completed onboarding keeps separate consent review state', () async {
    final fixture = _Fixture(user: user, profile: _profile(), consent: false);
    final now = DateTime.utc(2026, 7, 20);
    fixture.progressRepository.value = OnboardingProgress(
      id: 'state-a',
      userId: user.id,
      onboardingVersion: OnboardingV1Contract.version,
      status: OnboardingProgressStatus.completed,
      completedStepIds: OnboardingV1Contract.stepIds.toSet(),
      completedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await fixture.resolve();

    expect(fixture.state.userCompleted, isTrue);
    expect(fixture.state.requiresConsentReview, isTrue);
    expect(fixture.state.entryStatus, AppEntryStatus.authenticatedReady);
  });

  test(
    'complete is a no-op success when progress is already completed',
    () async {
      final fixture = _Fixture(user: user, profile: _profile(), consent: true);
      final now = DateTime.utc(2026, 7, 20);
      fixture.progressRepository.value = OnboardingProgress(
        id: 'state-a',
        userId: user.id,
        onboardingVersion: OnboardingV1Contract.version,
        status: OnboardingProgressStatus.completed,
        completedStepIds: OnboardingV1Contract.stepIds.toSet(),
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await fixture.resolve();
      final notifier = fixture.container.read(
        onboardingViewModelProvider.notifier,
      );

      expect(await notifier.complete(), isTrue);
      expect(await notifier.complete(), isTrue);
      expect(fixture.progressRepository.value!.completedAt, now);
    },
  );

  test(
    'local completion is published before slow remote reconciliation',
    () async {
      final fixture = _Fixture(
        user: user,
        profile: _profile(),
        consent: true,
        blockRemoteSync: true,
      );
      addTearDown(fixture.container.dispose);
      final now = DateTime.utc(2026, 7, 20);
      fixture.progressRepository.value = OnboardingProgress(
        id: 'state-a',
        userId: user.id,
        onboardingVersion: OnboardingV1Contract.version,
        status: OnboardingProgressStatus.completed,
        completedStepIds: OnboardingV1Contract.stepIds.toSet(),
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      fixture.container.read(onboardingViewModelProvider);
      for (
        var attempt = 0;
        attempt < 10 && !fixture.state.userCompleted;
        attempt++
      ) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(fixture.state.userCompleted, isTrue);
      expect(fixture.syncBootstrap.isWaiting, isTrue);
      fixture.syncBootstrap.release();
    },
  );
}

class _Fixture {
  _Fixture({
    required this.user,
    required Profile? profile,
    required bool consent,
    bool failProfileRead = false,
    bool hangProfileRead = false,
    Duration? sessionReadTimeout,
    bool blockProgressRead = false,
    bool blockRemoteSync = false,
  }) : _profileRepository = _ProfileRepository(
         profile,
         failRead: failProfileRead,
         hangRead: hangProfileRead,
       ),
       _privacyRepository = _PrivacyRepository(consent),
       repository = LocalOnboardingRepository(_Storage()),
       progressRepository = _OnboardingProgressRepository(
         blockReads: blockProgressRead,
       ),
       syncBootstrap = _SyncBootstrap(block: blockRemoteSync) {
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWithValue(user),
        syncBootstrapProvider.overrideWithValue(syncBootstrap),
        if (sessionReadTimeout != null)
          onboardingSessionReadTimeoutProvider.overrideWithValue(
            sessionReadTimeout,
          ),
        onboardingUseCasesProvider.overrideWithValue(
          OnboardingUseCases(repository),
        ),
        onboardingProgressRepositoryProvider.overrideWith(
          (ref) async => progressRepository,
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
  final _OnboardingProgressRepository progressRepository;
  final _SyncBootstrap syncBootstrap;
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
  _OnboardingProgressRepository({bool blockReads = false})
    : _readGate = blockReads ? Completer<void>() : null;

  OnboardingProgress? value;
  final Completer<void>? _readGate;
  int activeReads = 0;
  int maxConcurrentReads = 0;

  @override
  Future<OnboardingProgress?> getForUser() async {
    activeReads++;
    if (activeReads > maxConcurrentReads) maxConcurrentReads = activeReads;
    await _readGate?.future;
    activeReads--;
    return value;
  }

  @override
  Future<void> save(OnboardingProgress progress) async => value = progress;

  void release() {
    final gate = _readGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
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
  _SyncBootstrap({bool block = false})
    : _gate = block ? Completer<void>() : null;

  final Completer<void>? _gate;
  bool isWaiting = false;

  @override
  Future<void> dispose() async {}
  @override
  void initialize() {}
  @override
  void onBackgrounded() {}
  @override
  void onResumed() {}
  @override
  Future<void> retry() async {}
  @override
  Future<void> waitForInitialSync(
    String userId, {
    Duration timeout = const Duration(seconds: 4),
    Future<void>? cancelled,
  }) async {
    final gate = _gate;
    if (gate == null) return;
    isWaiting = true;
    await gate.future;
    isWaiting = false;
  }

  void release() {
    final gate = _gate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
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
  _ProfileRepository(
    this.value, {
    this.failRead = false,
    this.hangRead = false,
  });
  Profile? value;
  final bool failRead;
  final bool hangRead;
  @override
  Future<void> deleteProfile(Profile profile) async => value = null;
  @override
  Future<Profile?> getProfile() async {
    if (failRead) throw StateError('database unavailable');
    if (hangRead) return Completer<Profile?>().future;
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
