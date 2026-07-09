import '../../domain/entities/entities.dart';

class MedicalReportState {
  const MedicalReportState({
    this.report,
    this.isGenerating = false,
    this.isDownloading = false,
    this.isSharing = false,
    this.isPrinting = false,
    this.errorMessage,
  });

  final GeneratedMedicalReport? report;
  final bool isGenerating;
  final bool isDownloading;
  final bool isSharing;
  final bool isPrinting;
  final String? errorMessage;

  bool get hasReport => report != null;

  bool get isBusy => isGenerating || isDownloading || isSharing || isPrinting;

  MedicalReportState copyWith({
    GeneratedMedicalReport? report,
    bool? isGenerating,
    bool? isDownloading,
    bool? isSharing,
    bool? isPrinting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MedicalReportState(
      report: report ?? this.report,
      isGenerating: isGenerating ?? this.isGenerating,
      isDownloading: isDownloading ?? this.isDownloading,
      isSharing: isSharing ?? this.isSharing,
      isPrinting: isPrinting ?? this.isPrinting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
