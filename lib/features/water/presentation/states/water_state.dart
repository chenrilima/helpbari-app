import '../../../../core/formatters/app_water_formatter.dart';
import '../../../../core/services/clock_service.dart';
import '../../domain/entities/entities.dart';

class WaterState {
  const WaterState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
    this.syncWarning,
    this.clock = const AppClockService(),
  });

  final List<WaterRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final String? syncWarning;
  final ClockService clock;

  bool get hasRecords => records.isNotEmpty;

  WaterRecord? get latestRecord {
    if (records.isEmpty) {
      return null;
    }

    return records.first;
  }

  int get totalTodayInMl {
    final today = clock.now();

    return records
        .where(
          (record) =>
              record.recordedAt.year == today.year &&
              record.recordedAt.month == today.month &&
              record.recordedAt.day == today.day,
        )
        .fold<int>(0, (total, record) => total + record.amount.valueInMl);
  }

  String get formattedToday => AppWaterFormatter.ml(totalTodayInMl);

  WaterState copyWith({
    List<WaterRecord>? records,
    bool? isLoading,
    String? errorMessage,
    String? syncWarning,
    bool clearError = false,
    bool clearSyncWarning = false,
    ClockService? clock,
  }) {
    return WaterState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      syncWarning: clearSyncWarning ? null : syncWarning ?? this.syncWarning,
      clock: clock ?? this.clock,
    );
  }
}
