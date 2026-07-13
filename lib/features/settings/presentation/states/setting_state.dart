import '../../domain/entities/entities.dart';

class SettingsState {
  const SettingsState({
    this.settings = const AppSettings(id: 'local-settings'),
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final AppSettings settings;
  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
