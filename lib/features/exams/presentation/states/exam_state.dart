import '../../domain/entities/entities.dart';
import '../../../../core/media/media.dart';

enum ExamAttachmentStatus {
  none,
  localPending,
  uploading,
  synced,
  failed,
  removing,
}

class ExamState {
  const ExamState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.dateFilter,
    this.selectedExam,
    this.pendingAttachment,
    this.attachmentPreview,
    this.attachmentSignedUrl,
    this.attachmentStatus = ExamAttachmentStatus.none,
    this.attachmentError,
  });

  final List<Exam> items;

  final bool isLoading;
  final String? errorMessage;
  final DateTime? dateFilter;
  final Exam? selectedExam;
  final MediaFile? pendingAttachment;
  final MediaFile? attachmentPreview;
  final String? attachmentSignedUrl;
  final ExamAttachmentStatus attachmentStatus;
  final String? attachmentError;
  List<Exam> get filteredItems => items.where((item) {
    final d = dateFilter, v = item.examDate.value;
    return d == null ||
        (d.year == v.year && d.month == v.month && d.day == v.day);
  }).toList();

  bool get hasItems => items.isNotEmpty;

  Exam? get latestExam => hasItems ? items.first : null;

  ExamState copyWith({
    List<Exam>? items,
    bool? isLoading,
    String? errorMessage,
    DateTime? dateFilter,
    Exam? selectedExam,
    MediaFile? pendingAttachment,
    MediaFile? attachmentPreview,
    String? attachmentSignedUrl,
    ExamAttachmentStatus? attachmentStatus,
    String? attachmentError,
    bool clearError = false,
    bool clearDateFilter = false,
    bool clearSelected = false,
    bool clearPending = false,
    bool clearPreview = false,
    bool clearSignedUrl = false,
    bool clearAttachmentError = false,
  }) {
    return ExamState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      dateFilter: clearDateFilter ? null : dateFilter ?? this.dateFilter,
      selectedExam: clearSelected ? null : selectedExam ?? this.selectedExam,
      pendingAttachment: clearPending
          ? null
          : pendingAttachment ?? this.pendingAttachment,
      attachmentPreview: clearPreview
          ? null
          : attachmentPreview ?? this.attachmentPreview,
      attachmentSignedUrl: clearSignedUrl
          ? null
          : attachmentSignedUrl ?? this.attachmentSignedUrl,
      attachmentStatus: attachmentStatus ?? this.attachmentStatus,
      attachmentError: clearAttachmentError
          ? null
          : attachmentError ?? this.attachmentError,
    );
  }
}
