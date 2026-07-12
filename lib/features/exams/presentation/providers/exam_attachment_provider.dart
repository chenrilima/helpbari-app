import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/media/media.dart';
import '../../application/exam_attachment_service.dart';

final examAttachmentServiceProvider = Provider<ExamAttachmentService>(
  (ref) => ExamAttachmentService(
    storage: MediaUploadExamAttachmentStorage(
      ref.watch(mediaUploadServiceProvider),
    ),
    validation: ref.watch(mediaValidationServiceProvider),
    cache: ref.watch(mediaCacheServiceProvider),
  ),
);
