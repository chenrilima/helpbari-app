import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/create_profile_form.dart';
import '../providers/profile_use_case_providers.dart';
import '../states/profile_state.dart';

class ProfileViewModel extends Notifier<ProfileState> {
  ProfileUseCases get _useCases => ref.read(profileUseCasesProvider);
  LoggerService get _logger => ref.read(loggerServiceProvider);
  ClockService get _clock => ref.read(clockServiceProvider);

  @override
  ProfileState build() {
    ref.watch(authSessionProvider);
    return const ProfileState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _useCases.getProfile();

      state = state.copyWith(
        profile: profile,
        clearProfile: profile == null,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> createProfile(CreateProfileForm form) async {
    await saveProfile(form);
  }

  Future<void> saveProfile(CreateProfileForm form) async {
    state = state.copyWith(isLoading: true);

    try {
      final height = Height.create(form.height);
      final initialWeight = Weight.create(form.initialWeight);
      final targetWeight = form.targetWeight == null
          ? null
          : Weight.create(form.targetWeight!);

      if (height == null || initialWeight == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Dados inválidos para criar o perfil.',
        );
        return;
      }

      final user = ref.read(authSessionProvider);
      if (user == null) throw StateError('userId autenticado é obrigatório.');
      final current = state.profile;
      final profile = Profile(
        id: current?.id ?? user.id,
        name: form.name,
        email: form.email,
        birthDate: AppDate(form.birthDate, clock: _clock),
        height: height,
        initialWeight: initialWeight,
        targetWeight: targetWeight,
        surgeryDate: AppDate(form.surgeryDate, clock: _clock),
        surgeryType: form.surgeryType,
        createdAt: current?.createdAt ?? AppDate(_clock.now(), clock: _clock),
        photoUrl: current?.photoUrl,
        clock: _clock,
      );

      if (current == null) {
        await _useCases.saveProfile(profile);
      } else {
        await _useCases.updateProfile(profile);
      }
      _logger.info('Perfil Salvo.');

      state = state.copyWith(profile: profile, isLoading: false);
      _afterLocalCommit();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      _logger.error('Não salvou o perfil');
    }
  }

  Future<void> deleteProfile() async {
    final profile = state.profile;
    if (profile == null || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.deleteProfile(profile);
      state = state.copyWith(
        clearProfile: true,
        isLoading: false,
        hasLoaded: true,
      );
      _afterLocalCommit();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void _afterLocalCommit() {
    ref.invalidate(profileUseCasesProvider);
    ref.invalidate(homeViewModelProvider);
    unawaited(
      ref.read(syncManagerProvider.notifier).syncNow().catchError((_) => null),
    );
  }
}
