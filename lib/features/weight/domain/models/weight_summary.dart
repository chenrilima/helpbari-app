import '../entities/weight_record.dart';

class WeightSummary {
  const WeightSummary({required this.latestRecord, required this.hasRecords});

  final WeightRecord? latestRecord;
  final bool hasRecords;
}
