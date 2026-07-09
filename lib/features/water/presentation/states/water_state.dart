import '../../../../core/formatters/app_water_formatter.dart';
import '../../domain/entities/entities.dart';

class WaterState {
  const WaterState({this.records = const [], this.isLoading = false});

  final List<WaterRecord> records;
  final bool isLoading;

  bool get hasRecords => records.isNotEmpty;

  WaterRecord? get latestRecord {
    if (records.isEmpty) {
      return null;
    }

    return records.first;
  }

  int get totalTodayInMl {
    final today = DateTime.now();

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

  WaterState copyWith({List<WaterRecord>? records, bool? isLoading}) {
    return WaterState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
