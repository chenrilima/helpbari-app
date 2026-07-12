import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/charts/domain/models/chart_period.dart';

void main() {
  test('period boundaries use the local calendar day', () {
    final now = DateTime(2026, 7, 15, 23, 45);
    expect(ChartPeriod.sevenDays.startDate(now), DateTime(2026, 7, 9));
    expect(ChartPeriod.thirtyDays.startDate(now), DateTime(2026, 6, 16));
    expect(ChartPeriod.oneYear.startDate(now), DateTime(2025, 7, 16));
  });

  test('all supported periods retain their public labels', () {
    expect(ChartPeriod.values.map((period) => period.label), [
      '7 dias',
      '30 dias',
      '3 meses',
      '6 meses',
      '1 ano',
    ]);
  });
}
