import 'chart_point.dart';
import 'chart_type.dart';

class ChartSeries {
  const ChartSeries({
    required this.title,
    required this.points,
    required this.type,
    this.unit,
    this.emptyTitle = 'Sem dados suficientes',
    this.emptyDescription =
        'Registre novas informações para visualizar este gráfico.',
    this.referenceValue,
    this.referenceLabel,
  });

  final String title;
  final List<ChartPoint> points;
  final ChartType type;
  final String? unit;
  final String emptyTitle;
  final String emptyDescription;
  final double? referenceValue;
  final String? referenceLabel;

  bool get hasData => points.isNotEmpty;
}
