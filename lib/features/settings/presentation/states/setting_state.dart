import '../../domain/entities/entities.dart';

class SettingsState {
  const SettingsState({
    this.settings = const AppSettings(id: 'local-settings'),
    this.isLoading = false,
  });

  final AppSettings settings;
  final bool isLoading;

  SettingsState copyWith({AppSettings? settings, bool? isLoading}) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
