import '../../../../core/media/media.dart';
import '../../domain/entities/entities.dart';

enum ProfilePhotoStatus {
  none,
  localPending,
  uploading,
  synced,
  failed,
  removing,
}

class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.photoStatus = ProfilePhotoStatus.none,
    this.pendingPhoto,
    this.cachedPhoto,
    this.photoSignedUrl,
    this.photoSignedUrlExpiresAt,
    this.photoErrorMessage,
  });

  final Profile? profile;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final ProfilePhotoStatus photoStatus;
  final MediaFile? pendingPhoto;
  final MediaFile? cachedPhoto;
  final String? photoSignedUrl;
  final DateTime? photoSignedUrlExpiresAt;
  final String? photoErrorMessage;

  bool get isPhotoBusy =>
      photoStatus == ProfilePhotoStatus.uploading ||
      photoStatus == ProfilePhotoStatus.removing;

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearProfile = false,
    bool clearError = false,
    ProfilePhotoStatus? photoStatus,
    MediaFile? pendingPhoto,
    MediaFile? cachedPhoto,
    String? photoSignedUrl,
    DateTime? photoSignedUrlExpiresAt,
    String? photoErrorMessage,
    bool clearPendingPhoto = false,
    bool clearCachedPhoto = false,
    bool clearSignedUrl = false,
    bool clearPhotoError = false,
  }) => ProfileState(
    profile: clearProfile ? null : profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    photoStatus: photoStatus ?? this.photoStatus,
    pendingPhoto: clearPendingPhoto ? null : pendingPhoto ?? this.pendingPhoto,
    cachedPhoto: clearCachedPhoto ? null : cachedPhoto ?? this.cachedPhoto,
    photoSignedUrl: clearSignedUrl
        ? null
        : photoSignedUrl ?? this.photoSignedUrl,
    photoSignedUrlExpiresAt: clearSignedUrl
        ? null
        : photoSignedUrlExpiresAt ?? this.photoSignedUrlExpiresAt,
    photoErrorMessage: clearPhotoError
        ? null
        : photoErrorMessage ?? this.photoErrorMessage,
  );
}
