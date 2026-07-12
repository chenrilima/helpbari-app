import '../../domain/entities/entities.dart';
import '../../domain/value_objects/vitamin_status.dart';

class VitaminState {
  const VitaminState({
    this.vitamins = const [],
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.syncWarning,
  });
  final List<Vitamin> vitamins;
  final List<VitaminLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final String? syncWarning;
  bool get hasVitamins => vitamins.isNotEmpty;
  VitaminStatus statusFor(String vitaminId) =>
      logs.where((log) => log.vitaminId == vitaminId).firstOrNull?.status ??
      VitaminStatus.pending;
  int get pendingCount =>
      vitamins.where((v) => statusFor(v.id) == VitaminStatus.pending).length;
  VitaminState copyWith({
    List<Vitamin>? vitamins,
    List<VitaminLog>? logs,
    bool? isLoading,
    String? errorMessage,
    String? syncWarning,
    bool clearError = false,
    bool clearWarning = false,
  }) => VitaminState(
    vitamins: vitamins ?? this.vitamins,
    logs: logs ?? this.logs,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    syncWarning: clearWarning ? null : syncWarning ?? this.syncWarning,
  );
}
