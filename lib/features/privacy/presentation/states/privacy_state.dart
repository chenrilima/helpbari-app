import '../../domain/entities/entities.dart';

class PrivacyState {
  const PrivacyState({
    this.consents = const [],
    this.isLoading = false,
    this.isExporting = false,
    this.isDeleting = false,
    this.errorMessage,
    this.successMessage,
    this.exportedPath,
    this.passwordRequired = false,
  });

  final List<PrivacyConsent> consents;
  final bool isLoading;
  final bool isExporting;
  final bool isDeleting;
  final String? errorMessage;
  final String? successMessage;
  final String? exportedPath;
  final bool passwordRequired;

  PrivacyState copyWith({
    List<PrivacyConsent>? consents,
    bool? isLoading,
    bool? isExporting,
    bool? isDeleting,
    String? errorMessage,
    String? successMessage,
    String? exportedPath,
    bool? passwordRequired,
    bool clearMessages = false,
  }) => PrivacyState(
    consents: consents ?? this.consents,
    isLoading: isLoading ?? this.isLoading,
    isExporting: isExporting ?? this.isExporting,
    isDeleting: isDeleting ?? this.isDeleting,
    errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
    successMessage: clearMessages
        ? null
        : successMessage ?? this.successMessage,
    exportedPath: exportedPath ?? this.exportedPath,
    passwordRequired: passwordRequired ?? this.passwordRequired,
  );
}
