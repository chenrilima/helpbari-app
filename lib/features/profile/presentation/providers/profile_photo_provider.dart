import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/media.dart';
import '../../application/profile_photo_service.dart';

final profilePhotoServiceProvider = Provider<ProfilePhotoService>((ref) {
  return ProfilePhotoService(
    storage: MediaUploadProfilePhotoStorage(
      ref.watch(mediaUploadServiceProvider),
    ),
    validationService: ref.watch(mediaValidationServiceProvider),
    cacheService: ref.watch(mediaCacheServiceProvider),
  );
});
