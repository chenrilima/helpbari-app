import '../../domain/entities/entities.dart';

class WeightState {
  const WeightState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<WeightRecord> records;
  final bool isLoading;
  final String? errorMessage;

  WeightState copyWith({
    List<WeightRecord>? records,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WeightState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  WeightRecord? get latestRecord {
    if (records.isEmpty) {
      return null;
    }

    return records.first;
  }

  bool get hasRecords => records.isNotEmpty;
}
