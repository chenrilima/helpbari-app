import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/media/media.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../application/profile_photo_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/create_profile_form.dart';
import '../providers/profile_use_case_providers.dart';
import '../providers/profile_photo_provider.dart';
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
      if (profile?.photoStoragePath != null) {
        unawaited(loadPhotoView());
      } else {
        state = state.copyWith(
          photoStatus: ProfilePhotoStatus.none,
          clearSignedUrl: true,
          clearCachedPhoto: true,
        );
      }
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
    state = state.copyWith(isLoading: true, clearError: true);

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
        photoStoragePath: current?.photoStoragePath,
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

  Future<void> selectPhoto(MediaSource source) async {
    if (state.profile == null || state.isPhotoBusy) return;
    try {
      final file = await ref
          .read(mediaPickerServiceProvider)
          .pickImage(
            source: source,
            processingConfig: const MediaProcessingConfig(
              cropImages: true,
              compressImages: true,
              imageQuality: 82,
              minImageWidth: 1080,
              minImageHeight: 1080,
              cacheFiles: true,
            ),
          );
      if (file == null) return;
      final validation = ref
          .read(mediaValidationServiceProvider)
          .validateFile(file, config: ProfilePhotoService.validationConfig);
      if (validation != null) throw validation;
      state = state.copyWith(
        photoStatus: ProfilePhotoStatus.localPending,
        pendingPhoto: file,
        cachedPhoto: file,
        clearPhotoError: true,
      );
      unawaited(uploadPendingPhoto());
    } catch (error) {
      state = state.copyWith(
        photoStatus: ProfilePhotoStatus.failed,
        photoErrorMessage: error.toString(),
      );
    }
  }

  Future<void> uploadPendingPhoto() async {
    final user = ref.read(authSessionProvider);
    final profile = state.profile;
    final file = state.pendingPhoto;
    if (user == null || profile == null || file == null || state.isPhotoBusy) {
      return;
    }
    state = state.copyWith(
      photoStatus: ProfilePhotoStatus.uploading,
      clearPhotoError: true,
    );
    try {
      final uploaded = await ref
          .read(profilePhotoServiceProvider)
          .upload(
            userId: user.id,
            file: file,
            previousPath: profile.photoStoragePath,
          );
      final updated = profile.copyWith(photoStoragePath: uploaded.storagePath);
      await _useCases.updateProfile(updated);
      state = state.copyWith(
        profile: updated,
        photoStatus: ProfilePhotoStatus.synced,
        cachedPhoto: uploaded.cachedFile,
        photoSignedUrl: uploaded.signedUrl,
        photoSignedUrlExpiresAt: uploaded.signedUrlExpiresAt,
        clearPendingPhoto: true,
      );
      _afterLocalCommit();
    } catch (error) {
      state = state.copyWith(
        photoStatus: ProfilePhotoStatus.failed,
        photoErrorMessage: error.toString(),
      );
    }
  }

  Future<void> loadPhotoView() async {
    final user = ref.read(authSessionProvider);
    final path = state.profile?.photoStoragePath;
    if (user == null || path == null || state.isPhotoBusy) return;
    final expiresAt = state.photoSignedUrlExpiresAt;
    if (state.cachedPhoto != null &&
        state.photoSignedUrl != null &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now().add(const Duration(seconds: 15)))) {
      return;
    }
    try {
      final view = await ref
          .read(profilePhotoServiceProvider)
          .load(userId: user.id, path: path);
      state = state.copyWith(
        photoStatus: ProfilePhotoStatus.synced,
        cachedPhoto: view.file,
        photoSignedUrl: view.signedUrl,
        photoSignedUrlExpiresAt: view.signedUrlExpiresAt,
        clearPhotoError: true,
      );
    } catch (error) {
      state = state.copyWith(
        photoStatus: state.cachedPhoto == null
            ? ProfilePhotoStatus.failed
            : ProfilePhotoStatus.synced,
        photoErrorMessage: state.cachedPhoto == null ? error.toString() : null,
      );
    }
  }

  Future<void> removePhoto() async {
    final user = ref.read(authSessionProvider);
    final profile = state.profile;
    final path = profile?.photoStoragePath;
    if (user == null || profile == null || path == null || state.isPhotoBusy) {
      return;
    }
    state = state.copyWith(
      photoStatus: ProfilePhotoStatus.removing,
      clearPhotoError: true,
    );
    try {
      await ref
          .read(profilePhotoServiceProvider)
          .remove(userId: user.id, path: path);
      final updated = profile.copyWith(clearPhotoStoragePath: true);
      await _useCases.updateProfile(updated);
      state = state.copyWith(
        profile: updated,
        photoStatus: ProfilePhotoStatus.none,
        clearPendingPhoto: true,
        clearCachedPhoto: true,
        clearSignedUrl: true,
      );
      _afterLocalCommit();
    } catch (error) {
      state = state.copyWith(
        photoStatus: ProfilePhotoStatus.failed,
        photoErrorMessage: error.toString(),
      );
    }
  }

  void _afterLocalCommit() {
    ref.invalidate(profileUseCasesProvider);
    ref.invalidate(todayDashboardProvider);
    unawaited(
      ref.read(syncManagerProvider.notifier).syncNow().catchError((_) => null),
    );
  }
}
